# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'json'
require 'monitor'
require 'faye/websocket'
require 'fileutils'
require 'self_msgproto'
require_relative 'crypto'
require_relative 'messages/message'

module SelfSDK
  class WebsocketClient
    ON_DEMAND_CLOSE_CODE=3999

    attr_accessor :ws

    def initialize(url, auto_reconnect, authentication_hook, process_message_hook)
      @url = url
      @reconnection_delay = nil
      @auto_reconnect = auto_reconnect
      @authentication_hook = authentication_hook
      @process_message_hook = process_message_hook
    end

    # Creates a websocket connection and sets up its callbacks.
    def start
      SelfSDK.logger.debug "starting listener"
      @ws = Faye::WebSocket::Client.new(@url)
      SelfSDK.logger.debug "initialized"

      @ws.on :open do |_event|
        SelfSDK.logger.debug "websocket connection established"
        @authentication_hook.call
      end

      @ws.on :message do |event|
        @process_message_hook.call(event)
      end

      @ws.on :close do |event|
        SelfSDK.logger.debug "connection closed detected : #{event.code} #{event.reason}"

        if event.code != ON_DEMAND_CLOSE_CODE
          raise StandardError('websocket connection closed') if !@auto_reconnect

          if !@reconnection_delay.nil?
            SelfSDK.logger.debug "websocket connection closed (#{event.code}) #{event.reason}"
            sleep @reconnection_delay
            SelfSDK.logger.debug "reconnecting..."
          end

          @reconnection_delay = 3
          start
        end
      end
    end

    # Sends a closing message to the websocket client.
    def close
      @ws.close(ON_DEMAND_CLOSE_CODE, "connection closed by the client")
    end

    # Sends a ping message to the websocket server, but does 
    # not expect response.
    # This is kind of a hack to catch some corner cases where
    # the websocket client is not aware it has been disconnected.
    def ping
      @ws.ping 'ping'
    end

    def send(message)
      raise "client is not started, refer to start method on the main client" if @ws.nil?

      @ws.send(message.to_fb.bytes)
    end
  end

  class MessagingClient
    DEFAULT_DEVICE="1"
    DEFAULT_AUTO_RECONNECT=true
    DEFAULT_STORAGE_DIR="./.self_storage"

    PRIORITIES = { 
      'chat.invite':                 SelfSDK::Messages::PRIORITY_VISIBLE,
      'chat.join':                   SelfSDK::Messages::PRIORITY_INVISIBLE,
      'chat.message':                SelfSDK::Messages::PRIORITY_VISIBLE,
      'chat.message.delete':         SelfSDK::Messages::PRIORITY_INVISIBLE,
      'chat.message.delivered':      SelfSDK::Messages::PRIORITY_INVISIBLE,
      'chat.message.edit':           SelfSDK::Messages::PRIORITY_INVISIBLE,
      'chat.message.read':           SelfSDK::Messages::PRIORITY_INVISIBLE,
      'chat.remove':                 SelfSDK::Messages::PRIORITY_INVISIBLE,
      'document.sign.req':           SelfSDK::Messages::PRIORITY_VISIBLE,
      'identities.authenticate.req': SelfSDK::Messages::PRIORITY_VISIBLE,
      'identities.connections.req':  SelfSDK::Messages::PRIORITY_VISIBLE,
      'identities.facts.query.req':  SelfSDK::Messages::PRIORITY_VISIBLE,
      'identities.facts.issue':      SelfSDK::Messages::PRIORITY_VISIBLE,
      'identities.notify':           SelfSDK::Messages::PRIORITY_VISIBLE }.freeze

    attr_accessor :client, :jwt, :device_id, :ack_timeout, :timeout, :type_observer, :uuid_observer, :encryption_client, :source

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
      @raw_storage_dir = options.fetch(:storage_dir, DEFAULT_STORAGE_DIR)
      @storage_dir = "#{@raw_storage_dir}/apps/#{@jwt.id}/devices/#{@device_id}"
      FileUtils.mkdir_p @storage_dir unless File.exist? @storage_dir
      @source = SelfSDK::Sources.new("#{__dir__}/sources.json")
      @storage = SelfSDK::Storage.new(@client.jwt.id, @device_id, @storage_dir, storage_key)
      unless options.include? :no_crypto
        @encryption_client = Crypto.new(@client, @device_id, @storage, storage_key)
      end
      @offset = @storage.account_offset

      @ws = if options.include? :ws
              options[:ws]
            else
              WebsocketClient.new(url,
                                  options.fetch(:auto_reconnect, DEFAULT_AUTO_RECONNECT),
                                  -> { authenticate },
                                  ->(event) { on_message(event) })
            end
    end

    # Starts the underlying websocket connection.
    def start
      SelfSDK.logger.debug "starting"
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
        loop do
          sleep 10
          clean_timeouts
          @ws.ping
        end
      end

      @mon.synchronize do
        @acks[auth_id][:waiting_cond].wait_while { @acks[auth_id][:waiting] }
        @acks.delete(auth_id)
      end

      return unless @acks.include? auth_id

      # In case this does not succeed start the process again.
      if @acks[auth_id][:waiting]
        close
        start_connection
      end
      @acks.delete(auth_id)
    end

    # Stops the underlying websocket connection.
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
      @ws.close
    end

    # Checks if the session with a specified identity / device is already created.
    def session?(identifier, device)
      path = @encryption_client.session_path(identifier, device)
      File.file?(path)
    end

    # Send custom mmessage
    #
    # @param recipient [string] selfID to be requested
    # @param type [string] message type
    # @param request [hash] original message requesing information
    def send_custom(recipients, request_body)
      # convert argument into an array if is a string
      recipients = [recipients] if recipients.is_a? String

      # send to current identity devices except the current one.
      recipients |= [@jwt.id]

      # build recipients list
      recs = []
      recipients.each do |r|
        @client.devices(r).each do |to_device|
          recs << { id: r, device_id: to_device }
        end
      end

      SelfSDK.logger.debug "sending custom message #{request_body.to_json}"
      current_device = "#{@jwt.id}:#{@device_id}"

      recs.each do |r|
        next if current_device == "#{r[:id]}:#{r[:device_id]}"

        request_body[:sub] = r[:id]
        request_body[:aud] = r[:id] unless request_body.key?(:aud)
        ciphertext = @encryption_client.encrypt(@jwt.prepare(request_body), recs)

        m = SelfMsg::Message.new
        m.id = SecureRandom.uuid
        m.sender = current_device
        m.recipient = "#{r[:id]}:#{r[:device_id]}"
        m.ciphertext = ciphertext
        m.message_type = r[:typ]
        m.priority = select_priority(r[:typ])

        SelfSDK.logger.debug "[#{m.id}] -> to #{m.recipient}"
        send_message m
      end
    end

    # Sends a command to list ACL rules.
    def list_acl_rules
      wait_for 'acl_list' do
        a = SelfMsg::Acl.new
        a.id = SecureRandom.uuid
        a.command = SelfMsg::AclCommandLIST

        @ws.send a
      end
    end

    # Sends a message and waits for the response
    #
    # @params msg [SelfMsg::Message] message object to be sent
    def send_and_wait_for_response(msgs, original)
      SelfSDK.logger.debug "sending/wait for #{msgs.first.id}"
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
      SelfSDK.logger.debug "sending #{uuid}"
      @mon.synchronize do
        @messages[uuid] = {
          waiting_cond: @mon.new_cond,
          waiting: true,
          timeout: SelfSDK::Time.now + @timeout,
          original_message: msg,
        }
      end

      yield

      SelfSDK.logger.debug "waiting for client to respond #{uuid}"
      @mon.synchronize do
        @messages[uuid][:waiting_cond].wait_while do
          @messages[uuid][:waiting]
        end
      end

      SelfSDK.logger.debug "response received for #{uuid}"
      @messages[uuid][:response]
    ensure
      @messages.delete(uuid)
    end

    # Send a message through self network
    #
    # @params msg [SelfMsg::Message] message object to be sent
    def send_message(msg)
      uuid = msg.id
      @mon.synchronize do
        @acks[uuid] = {
          waiting_cond: @mon.new_cond,
          waiting: true,
          timeout: SelfSDK::Time.now + @ack_timeout,
        }
      end
      @ws.send msg
      SelfSDK.logger.debug "waiting for acknowledgement #{uuid}"
      @mon.synchronize do
        @acks[uuid][:waiting_cond].wait_while do
          @acks[uuid][:waiting]
        end
      end

      # response has timed out
      if @acks[uuid][:timed_out]
        SelfSDK.logger.debug "acknowledgement response timed out re-sending message #{uuid}"
        return send_message(msg)
      end

      SelfSDK.logger.debug "acknowledged #{uuid}"
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
        SelfSDK.logger.debug " - notifying by id"
        observer = @uuid_observer[message.id]
        message.validate!(observer[:original_message]) if observer.include?(:original_message)
        Thread.new do
          @uuid_observer[message.id][:block].call(message)
          @uuid_observer.delete(message.id)
        end
        return
      end

      SelfSDK.logger.debug " - notifying by type"
      SelfSDK.logger.debug " - #{message.typ}"
      SelfSDK.logger.debug " - #{message}"
      SelfSDK.logger.debug " - #{@type_observer.keys.join(',')}"

      # Return if there is no observer setup for this kind of message
      return unless @type_observer.include? message.typ

      SelfSDK.logger.debug " - notifying by type (Y)"
      Thread.new do
        @type_observer[message.typ][:block].call(message)
      end
    end

    def set_observer(original, options = {}, &block)
      request_timeout = options.fetch(:timeout, @timeout)
      @uuid_observer[original.id] = { original_message: original, block: block, timeout: SelfSDK::Time.now + request_timeout }
    end

    def subscribe(type, &block)
      type = @source.message_type(type) if type.is_a? Symbol
      @type_observer[type] = { block: block }
    end

    private


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
          SelfSDK.logger.debug "[#{uuid}] message response timed out"
          list[uuid][:waiting] = false
          list[uuid][:waiting_cond].broadcast
          list[uuid][:timed_out] = true
        end
      end
    end

    # Creates a websocket connection and sets up its callbacks.
    def start_connection
      @ws.start
    end


    # Process an event when it arrives through the websocket connection.
    def on_message(event)
      data = event.data.pack('c*')
      hdr = SelfMsg::Header.new(data: data)

      SelfSDK.logger.debug " - received #{hdr.id} (#{hdr.type})"
      case hdr.type
      when SelfMsg::MsgTypeMSG
        SelfSDK.logger.debug "[#{hdr.id}] message received"
        m = SelfMsg::Message.new(data: data)
        process_incomming_message m
      when SelfMsg::MsgTypeACK
        SelfSDK.logger.debug "[#{hdr.id}] acknowledged"
        mark_as_acknowledged hdr.id
      when SelfMsg::MsgTypeERR
        SelfSDK.logger.warn "error on #{hdr.id}"
        e = SelfMsg::Notification.new(data: data)
        SelfSDK.logger.warn "#{e.error}"
        # TODO control @messages[hdr.id] being nil
        raise "ERROR : #{e.error}" if @messages[hdr.id].nil?

        @messages[hdr.id][:response] = {error: e.error}
        mark_as_acknowledged(hdr.id)
        mark_as_arrived(hdr.id)
      when SelfMsg::MsgTypeACL
        SelfSDK.logger.debug "#{hdr.id} ACL received"
        a = SelfMsg::Acl.new(data: data)
        process_incomming_acl a
      end
    rescue TypeError
      SelfSDK.logger.debug "invalid array message"
    end

    def process_incomming_acl(input)
      list = JSON.parse(input.payload)

      @messages['acl_list'][:response] = list
      mark_as_arrived 'acl_list'
    rescue StandardError => e
      p "Error processing incoming ACL #{input.id} #{input.payload}"
      SelfSDK.logger.debug e
      SelfSDK.logger.debug e.backtrace
      nil
    end

    def process_incomming_message(input)
      message = parse_and_write_offset(input)

      if @messages.include? message.id
        message.validate! @messages[message.id][:original_message]
        @messages[message.id][:response] = message
        mark_as_arrived message.id
      else
        SelfSDK.logger.debug "Received async message #{input.id}"
        message.validate! @uuid_observer[message.id][:original_message] if @uuid_observer.include? message.id
        SelfSDK.logger.debug "[#{input.id}] is valid, notifying observer"
        notify_observer(message)
      end
    rescue StandardError => e
      p "Error processing incoming message #{e.message}"
      SelfSDK.logger.debug e
      # p e.backtrace
      nil
    end

    def parse_and_write_offset(input)
      msg = SelfSDK::Messages.parse(input, self)
      @storage.account_set_offset(input.offset)
      # Avoid catching any other decryption errors.
      msg
    rescue SelfSDK::Messages::UnmappedMessage
      # this is an ummapped message, let's ignore it but write the offset.
      @storage.account_set_offset(input.offset)
      nil
    end

    # Authenticates current client on the websocket server.
    def authenticate
      @auth_id = SecureRandom.uuid if @auth_id.nil?
      @offset = @storage.account_offset

      SelfSDK.logger.debug "authenticating with offset (#{@offset})"

      a = SelfMsg::Auth.new
      a.id = @auth_id
      a.token = @jwt.auth_token
      a.device = @device_id
      a.offset = @offset

      @ws.send a

      @auth_id = nil
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

    def select_priority(mtype)
      PRIORITIES[mtype] || SelfSDK::Messages::PRIORITY_VISIBLE
    end
  end
end
