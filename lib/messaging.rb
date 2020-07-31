# frozen_string_literal: true

require 'json'
require 'monitor'
require 'faye/websocket'
require_relative 'messages/message'
require_relative 'proto/auth_pb'
require_relative 'proto/message_pb'
require_relative 'proto/msgtype_pb'
require_relative 'proto/acl_pb'
require_relative 'proto/aclcommand_pb'

module Selfid
  class MessagingClient
    DEFAULT_DEVICE="1"
    DEFAULT_AUTO_RECONNECT=true
    DEFAULT_STORAGE_DIR="./.self_storage"
    ON_DEMAND_CLOSE_CODE=3999

    attr_accessor :client, :jwt, :device_id, :ack_timeout, :timeout, :type_observer, :uuid_observer

    # RestClient initializer
    #
    # @param url [string] self-messaging url
    # @params client [Object] Selfid::Client object
    # @param app_id [string] the app id provided by developer portal.
    # @option opts [string] :storage_dir  the folder where encryption sessions and settings will be stored
    # @option opts [Bool] :auto_reconnect Automatically reconnects to websocket if connection is lost (defaults to true).
    # @option opts [String] :device_id The device id to be used by the app defaults to "1".
    def initialize(url, client, app_id, options = {})
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
      @app_id = app_id
      @device_id = options.fetch(:device_id, DEFAULT_DEVICE)
      @auto_reconnect = options.fetch(:auto_reconnect, DEFAULT_AUTO_RECONNECT)
      @storage_dir = options.fetch(:storage_dir, DEFAULT_STORAGE_DIR)
      @offset_file = "#{@storage_dir}/#{@app_id}:#{@device_id}.offset"
      @offset = read_offset

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
        @to_device = @client.devices(recipient).first
        send_message msg = Msgproto::Message.new(
          type: Msgproto::MsgType::MSG,
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
    def send_and_wait_for_response(msg, original)
      wait_for msg.id, original do
        send_message msg
      end
    end

    # Executes the given block and waits for the message id specified on
    # the uuid.
    #
    # @params uuid [string] unique identifier for a conversation
    def wait_for(uuid, msg = nil)
      Selfid.logger.info "sending #{uuid}"
      @mon.synchronize do
        @messages[uuid] = {
          waiting_cond: @mon.new_cond,
          waiting: true,
          timeout: Selfid::Time.now + @timeout,
          original_message: msg,
        }
      end

      yield

      Selfid.logger.info "waiting for client to respond #{uuid}"
      @mon.synchronize do
        @messages[uuid][:waiting_cond].wait_while do
          @messages[uuid][:waiting]
        end
      end

      Selfid.logger.info "response received for #{uuid}"
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
          timeout: Selfid::Time.now + @ack_timeout,
        }
      end
      send_raw(msg)
      Selfid.logger.info "waiting for acknowledgement #{uuid}"
      @mon.synchronize do
        @acks[uuid][:waiting_cond].wait_while do
          @acks[uuid][:waiting]
        end
      end
      Selfid.logger.info "acknowledged #{uuid}"
      true
    ensure
      @acks.delete(uuid)
      false
    end

    def clean_observers
      live = {}
      @uuid_observer.clone.each do |id, msg|
        if msg[:timeout] < Selfid::Time.now
          message = Selfid::Messages::Base.new(self)
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
      @uuid_observer[original.id] = { original_message: original, block: block, timeout: Selfid::Time.now + request_timeout }
    end

    def subscribe(type, &block)
      type = Selfid::message_type(type) if type.is_a? Symbol
      @type_observer[type] = { block: block }
    end

    private

    # Start sthe websocket listener
    def start
      Selfid.logger.info "starting"
      @mon.synchronize do
        @acks["authentication"] = { waiting_cond: @mon.new_cond,
                                    waiting: true,
                                    timeout: Selfid::Time.now + @ack_timeout }
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
        @acks["authentication"][:waiting_cond].wait_while { @acks["authentication"][:waiting] }
        @acks.delete("authentication")
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
        next unless list[uuid][:timeout] < Selfid::Time.now

        @mon.synchronize do
          Selfid.logger.info "message response timed out #{uuid}"
          list[uuid][:waiting] = false
          list[uuid][:waiting_cond].broadcast
        end
      end
    end

    # Creates a websocket connection and sets up its callbacks.
    def start_connection
      Selfid.logger.info "starting listener"
      @ws = Faye::WebSocket::Client.new(@url)
      Selfid.logger.info "initialized"

      @ws.on :open do |_event|
        Selfid.logger.info "websocket connection established"
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
            Selfid.logger.info "websocket connection closed (#{event.code}) #{event.reason}"
            sleep @reconnection_delay
            Selfid.logger.info "reconnecting..."
          end
          @reconnection_delay = 3
          start_connection
        end
      end
    end

    # Pings the websocket server to keep the connection alive.
    def ping
      # Selfid.logger.info "ping"
      @ws&.ping
    end

    # Process an event when it arrives through the websocket connection.
    def on_message(event)
      input = Msgproto::Message.decode(event.data.pack('c*'))
      Selfid.logger.info " - received #{input.id} (#{input.type})"
      case input.type
      when :ERR
        Selfid.logger.info "error #{input.sender} on #{input.id}"
        mark_as_arrived(input.id)
      when :ACK
        Selfid.logger.info "#{input.id} acknowledged"
        mark_as_acknowledged input.id
      when :ACL
        Selfid.logger.info "ACL received"
        process_incomming_acl input
      when :MSG
        Selfid.logger.info "Message #{input.id} received"
        process_incomming_message input
      end
    rescue TypeError
      Selfid.logger.info "invalid array message"
    end

    def process_incomming_acl(input)
      list = JSON.parse(input.recipient)

      @messages['acl_list'][:response] = list
      mark_as_arrived 'acl_list'
    rescue StandardError => e
      p "Error processing incoming ACL #{input.to_json}"
      Selfid.logger.info e
      Selfid.logger.info e.backtrace
      nil
    end

    def process_incomming_message(input)
      message = Selfid::Messages.parse(input, self)

      if @messages.include? message.id
        message.validate! @messages[message.id][:original_message]
        @messages[message.id][:response] = message
        mark_as_arrived message.id
      else
        Selfid.logger.info "Received async message #{input.id}"
        message.validate! @uuid_observer[message.id][:original_message] if @uuid_observer.include? message.id
        notify_observer(message)
      end

      @offset = message.offset
      write_offset(@offset)
    rescue StandardError => e
      p "Error processing incoming message #{input.to_json}"
      Selfid.logger.info e
      p e.backtrace
      nil
    end

    # Authenticates current client on the websocket server.
    def authenticate
      Selfid.logger.info "authenticating"
      send_raw Msgproto::Auth.new(
        type: Msgproto::MsgType::AUTH,
        id: "authentication",
        token: @jwt.auth_token,
        device: @device_id,
        offset: @offset,
      )
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
        return f.read.unpack('q')
      end
    end

    def write_offset(offset)
      File.open(@offset_file, 'wb') do |f|
        f.write([offset].pack('q'))
      end
    end
  end
end
