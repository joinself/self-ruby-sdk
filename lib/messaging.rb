# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'json'
require 'monitor'
require 'faye/websocket'
require 'fileutils'
require_relative 'crypto'
require_relative 'messages/message'
require_relative 'proto/auth_pb'
require_relative 'proto/message_pb'
require_relative 'proto/msgtype_pb'
require_relative 'proto/acl_pb'
require_relative 'proto/aclcommand_pb'

module SelfSDK
  class MessagingClient
    DEFAULT_DEVICE="1"
    DEFAULT_AUTO_RECONNECT=true
    DEFAULT_STORAGE_DIR="./.self_storage"
    ON_DEMAND_CLOSE_CODE=3999

    attr_accessor :client, :jwt, :device_id, :ack_timeout, :timeout, :type_observer, :uuid_observer, :encryption_client

    # RestClient initializer
    #
    # @param url [string] self-messaging url
    # @params client [Object] SelfSDK::Client object
    # @option opts [string] :storage_dir  the folder where encryption sessions and settings will be stored
    # @params storage_key [String] seed to encrypt messaging
    # @params storage_folder [String] folder to perist messaging encryption
    # @option opts [Bool] :auto_reconnect Automatically reconnects to websocket if connection is lost (defaults to true).
    # @option opts [String] :device_id The device id to be used by the app defaults to "1".
    def initialize(url, client, storage_key, options = {})
      @mon = Monitor.new
      @url = url
      @messages = {}
      @acks = {}
      @type_observer = {}
      @uuid_observer = {}
      @jwt = client.jwt
      @client = client
      @ack_timeout = 60 # seconds
      @timeout = 120 # seconds
      @auth_id = SecureRandom.uuid
      @device_id = options.fetch(:device_id, DEFAULT_DEVICE)
      @auto_reconnect = options.fetch(:auto_reconnect, DEFAULT_AUTO_RECONNECT)
      @raw_storage_dir = options.fetch(:storage_dir, DEFAULT_STORAGE_DIR)
      @storage_dir = "#{@raw_storage_dir}/apps/#{@jwt.id}/devices/#{@device_id}"
      FileUtils.mkdir_p @storage_dir unless File.exist? @storage_dir
      @offset_file = "#{@storage_dir}/#{@jwt.id}:#{@device_id}.offset"
      @offset = read_offset
      migrate_old_storage_format

      unless options.include? :no_crypto
        crypto_path = "#{@storage_dir}/keys"
        FileUtils.mkdir_p crypto_path unless File.exist? crypto_path
        @encryption_client = Crypto.new(@client, @device_id, crypto_path, storage_key)
      end

      if options.include? :ws
        @ws = options[:ws]
      else
        start
      end
    end

    def stop
      @acks.each do |k, _v|
        mark_as_acknowledged(k)
      end
      @messages.each do |k, _v|
        mark_as_acknowledged(k)
        mark_as_arrived(k)
      end
    end

    def close
      @ws.close(ON_DEMAND_CLOSE_CODE, "connection closed by the client")
    end

    # Responds a request information request
    #
    # @param recipient [string] selfID to be requested
    # @param recipient_device [string] device id for the selfID to be requested
    # @param request [string] original message requesing information
    def share_information(recipient, recipient_device, request)
      send_message Msgproto::Message.new(
        type: Msgproto::MsgType::MSG,
        sub_type: Msgproto::MsgSubType::Unknown,
        id: SecureRandom.uuid,
        sender: "#{@jwt.id}:#{@device_id}",
        recipient: "#{recipient}:#{recipient_device}",
        ciphertext: @jwt.prepare(request),
      )
    end

    # Send custom mmessage
    #
    # @param recipient [string] selfID to be requested
    # @param type [string] message type
    # @param request [hash] original message requesing information
    def send_custom(recipient, request_body)
      # TODO (adriacidre) this is sending the message to the first device only
        @to_device = @client.devices(recipient).first
        send_message msg = Msgproto::Message.new(
          type: Msgproto::MsgType::MSG,
          sub_type: Msgproto::MsgSubType::Unknown,
          id: SecureRandom.uuid,
          sender: "#{@jwt.id}:#{@device_id}",
          recipient: "#{recipient}:#{@to_device}",
          ciphertext: @jwt.prepare(request_body),
        )
    end

    # Allows incomming messages from the given identity
    #
    # @params payload [string] base64 encoded payload to be sent
    def add_acl_rule(payload)
      send_message Msgproto::AccessControlList.new(
        type: Msgproto::MsgType::ACL,
        id: SecureRandom.uuid,
        command: Msgproto::ACLCommand::PERMIT,
        payload: payload,
      )
    end

    # Blocks incoming messages from specified identities
    #
    # @params payload [string] base64 encoded payload to be sent
    def remove_acl_rule(payload)
      send_message Msgproto::AccessControlList.new(
        type: Msgproto::MsgType::ACL,
        id: SecureRandom.uuid,
        command: Msgproto::ACLCommand::REVOKE,
        payload: payload,
      )
    end

    # Lists acl rules
    def list_acl_rules
      wait_for 'acl_list' do
        send_raw Msgproto::AccessControlList.new(
          type: Msgproto::MsgType::ACL,
          id: SecureRandom.uuid,
          command: Msgproto::ACLCommand::LIST,
        )
      end
    end

    # Sends a message and waits for the response
    #
    # @params msg [Msgproto::Message] message object to be sent
    def send_and_wait_for_response(msgs, original)
      wait_for msgs.first.id, original do
        msgs.each do |msg|
          send_message msg
        end
      end
    end

    # Executes the given block and waits for the message id specified on
    # the uuid.
    #
    # @params uuid [string] unique identifier for a conversation
    def wait_for(uuid, msg = nil)
      SelfSDK.logger.info "sending #{uuid}"
      @mon.synchronize do
        @messages[uuid] = {
          waiting_cond: @mon.new_cond,
          waiting: true,
          timeout: SelfSDK::Time.now + @timeout,
          original_message: msg,
        }
      end

      yield

      SelfSDK.logger.info "waiting for client to respond #{uuid}"
      @mon.synchronize do
        @messages[uuid][:waiting_cond].wait_while do
          @messages[uuid][:waiting]
        end
      end

      SelfSDK.logger.info "response received for #{uuid}"
      @messages[uuid][:response]
    ensure
      @messages.delete(uuid)
    end

    # Send a message through self network
    #
    # @params msg [Msgproto::Message] message object to be sent
    def send_message(msg)
      uuid = msg.id
      @mon.synchronize do
        @acks[uuid] = {
          waiting_cond: @mon.new_cond,
          waiting: true,
          timeout: SelfSDK::Time.now + @ack_timeout,
        }
      end
      send_raw(msg)
      SelfSDK.logger.info "waiting for acknowledgement #{uuid}"
      @mon.synchronize do
        @acks[uuid][:waiting_cond].wait_while do
          @acks[uuid][:waiting]
        end
      end
      SelfSDK.logger.info "acknowledged #{uuid}"
      true
    ensure
      @acks.delete(uuid)
      false
    end

    def clean_observers
      live = {}
      @uuid_observer.clone.each do |id, msg|
        if msg[:timeout] < SelfSDK::Time.now
          message = SelfSDK::Messages::Base.new(self)
          message.status = "errored"

          @uuid_observer[id][:block].call(message)
          @uuid_observer.delete(id)
        else
          live[id] = msg
        end
      end
      @uuid_observer = live
    end

    # Notify the type observer for the given message
    def notify_observer(message)
      if @uuid_observer.include? message.id
        observer = @uuid_observer[message.id]
        message.validate!(observer[:original_message]) if observer.include?(:original_message)
        Thread.new do
          @uuid_observer[message.id][:block].call(message)
          @uuid_observer.delete(message.id)
        end
        return
      end

      # Return if there is no observer setup for this kind of message
      return unless @type_observer.include? message.typ

      Thread.new do
        @type_observer[message.typ][:block].call(message)
      end
    end

    def set_observer(original, options = {}, &block)
      request_timeout = options.fetch(:timeout, @timeout)
      @uuid_observer[original.id] = { original_message: original, block: block, timeout: SelfSDK::Time.now + request_timeout }
    end

    def subscribe(type, &block)
      type = SelfSDK::message_type(type) if type.is_a? Symbol
      @type_observer[type] = { block: block }
    end

    private

    # Start sthe websocket listener
    def start
      SelfSDK.logger.info "starting"
      auth_id = @auth_id.dup

      @mon.synchronize do
        @acks[auth_id] = { waiting_cond: @mon.new_cond,
                                    waiting: true,
                                    timeout: SelfSDK::Time.now + @ack_timeout }
      end

      Thread.new do
        EM.run start_connection
      end

      Thread.new do
        loop { sleep 10; clean_timeouts }
      end

      Thread.new do
        loop { sleep 30; ping }
      end

      @mon.synchronize do
        @acks[auth_id][:waiting_cond].wait_while { @acks[auth_id][:waiting] }
        @acks.delete(auth_id)
      end
      # In case this does not succeed start the process again.
      if @acks.include? auth_id
        if @acks[auth_id][:waiting]
          close
          start_connection
        end
        @acks.delete(auth_id)
      end
    end

    # Cleans expired messages
    def clean_timeouts
      clean_observers
      clean_timeouts_for(@messages)
      clean_timeouts_for(@acks)
    end

    def clean_timeouts_for(list)
      list.clone.each do |uuid, _msg|
        next unless list[uuid][:timeout] < SelfSDK::Time.now

        @mon.synchronize do
          SelfSDK.logger.info "message response timed out #{uuid}"
          list[uuid][:waiting] = false
          list[uuid][:waiting_cond].broadcast
        end
      end
    end

    # Creates a websocket connection and sets up its callbacks.
    def start_connection
      SelfSDK.logger.info "starting listener"
      @ws = Faye::WebSocket::Client.new(@url)
      SelfSDK.logger.info "initialized"

      @ws.on :open do |_event|
        SelfSDK.logger.info "websocket connection established"
        authenticate
      end

      @ws.on :message do |event|
        on_message(event)
      end

      @ws.on :close do |event|
        if event.code == ON_DEMAND_CLOSE_CODE
          puts "client closed connection"
        else
          if !@auto_reconnect
            raise StandardError "websocket connection closed"
          end
          if !@reconnection_delay.nil?
            SelfSDK.logger.info "websocket connection closed (#{event.code}) #{event.reason}"
            sleep @reconnection_delay
            SelfSDK.logger.info "reconnecting..."
          end
          @reconnection_delay = 3
          start_connection
        end
      end
    end

    # Pings the websocket server to keep the connection alive.
    def ping
      # SelfSDK.logger.info "ping"
      @ws&.ping
    end

    # Process an event when it arrives through the websocket connection.
    def on_message(event)
      input = Msgproto::Message.decode(event.data.pack('c*'))
      SelfSDK.logger.info " - received #{input.id} (#{input.type})"
      case input.type
      when :ERR
        SelfSDK.logger.info "error #{input.sender} on #{input.id}"
        mark_as_arrived(input.id)
      when :ACK
        SelfSDK.logger.info "#{input.id} acknowledged"
        mark_as_acknowledged input.id
      when :ACL
        SelfSDK.logger.info "ACL received"
        process_incomming_acl input
      when :MSG
        SelfSDK.logger.info "Message #{input.id} received"
        process_incomming_message input
      end
    rescue TypeError
      SelfSDK.logger.info "invalid array message"
    end

    def process_incomming_acl(input)
      list = JSON.parse(input.recipient)

      @messages['acl_list'][:response] = list
      mark_as_arrived 'acl_list'
    rescue StandardError => e
      p "Error processing incoming ACL #{input.to_json}"
      SelfSDK.logger.info e
      SelfSDK.logger.info e.backtrace
      nil
    end

    def process_incomming_message(input)
      message = SelfSDK::Messages.parse(input, self)
      @offset = input.offset
      write_offset(@offset)

      if @messages.include? message.id
        message.validate! @messages[message.id][:original_message]
        @messages[message.id][:response] = message
        mark_as_arrived message.id
      else
        SelfSDK.logger.info "Received async message #{input.id}"
        message.validate! @uuid_observer[message.id][:original_message] if @uuid_observer.include? message.id
        notify_observer(message)
      end

    rescue StandardError => e
      p "Error processing incoming message #{input.to_json}"
      SelfSDK.logger.info e
      p e.backtrace
      nil
    end

    # Authenticates current client on the websocket server.
    def authenticate
      @auth_id = SecureRandom.uuid if @auth_id.nil?

      SelfSDK.logger.info "authenticating"
      send_raw Msgproto::Auth.new(
        type: Msgproto::MsgType::AUTH,
        id: @auth_id,
        token: @jwt.auth_token,
        device: @device_id,
        offset: @offset,
      )
      
      @auth_id = nil
    end

    def send_raw(msg)
      @ws.send(msg.to_proto.bytes)
    end

    # Marks a message as arrived.
    def mark_as_arrived(id)
      # Return if no one is waiting for this message
      return unless @messages.include? id

      @mon.synchronize do
        @messages[id][:waiting] = false
        @messages[id][:waiting_cond].broadcast
      end
    end

    # Marks a message as acknowledged by the server.
    def mark_as_acknowledged(id)
      return unless @acks.include? id

      @mon.synchronize do
        @acks[id][:waiting] = false
        @acks[id][:waiting_cond].broadcast
      end
    end

    def read_offset
      return 0 unless File.exist? @offset_file

      File.open(@offset_file, 'rb') do |f|
        return f.read.to_i
      end
    end

    def write_offset(offset)
      File.open(@offset_file, 'wb') do |f|
        f.flock(File::LOCK_EX)
        f.write(offset.to_s.rjust(19, "0"))
      end
    end

    def migrate_old_storage_format
      # Move the offset file
      old_offset_file = "#{@raw_storage_dir}/#{@jwt.id}:#{@device_id}.offset"
      if File.file?(old_offset_file)
        File.open(old_offset_file, 'rb') do |f|
          offset = f.read.unpack('q')[0]
          write_offset(offset)
        end
        File.delete(old_offset_file)
      end
      
      # Move all pickle files
      crypto_path = "#{@storage_dir}/keys/#{@jwt.key_id}"
      FileUtils.mkdir_p crypto_path unless File.exist? crypto_path
      Dir[File.join(@raw_storage_dir, "*.pickle")].each do |file|
        filename = File.basename(file, ".pickle")
        File.rename file, "#{crypto_path}/#{filename}.pickle"
      end
        
    end
  end
end
