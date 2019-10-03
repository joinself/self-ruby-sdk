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
    attr_accessor :inbox, :client, :jwt, :device_id

    # RestClient initializer
    #
    # @param url [string] self-messaging url
    # @param jwt [Object] Selfid::Jwt object
    # @params client [Object] Selfid::Client object
    def initialize(url, jwt, client)
      @inbox = {}
      @mon = Monitor.new
      @url = url
      @device_id = "1"
      @messages = {}
      @acks = {}
      @jwt = jwt
      @client = client
      @device_id = "1"
      @timeout = 30
      start
    end

    def stop
      @listener.stop unles listener.nil?
    end

    # Responds a request information request
    #
    # @param recipient [string] selfID to be requested
    # @param recipient_device [string] device id for the selfID to be requested
    # @param request [string] original message requesing information
    def share_information(recipient, recipient_device, request)
      send Msgproto::Message.new(
        type: Msgproto::MsgType::MSG,
        id: SecureRandom.uuid,
        sender: "#{@jwt.id}:#{@device_id}",
        recipient: "#{recipient}:#{recipient_device}",
        ciphertext: @jwt.prepare_encoded(request),
      )
    end

    # Allows authenticated user to receive incoming messages from the given id
    #
    # @params payload [string] base64 encoded payload to be sent
    def connect(payload)
      send Msgproto::AccessControlList.new(
        type: Msgproto::MsgType::ACL,
        id: SecureRandom.uuid,
        command: Msgproto::ACLCommand::PERMIT,
        payload: payload,
      )
    end

    def send_and_wait_for_response(msg)
      uuid = msg.id

      Selfid.logger.info "sending #{uuid}"
      @mon.synchronize do
        @messages[uuid] = {
          waiting_cond: @mon.new_cond,
          waiting: true,
          timeout: Selfid::Time.now + @timeout,
        }
      end
      send msg

      Selfid.logger.info "waiting for client to respond #{uuid}"
      @mon.synchronize do
        @messages[uuid][:waiting_cond].wait_while do
          @messages[uuid][:waiting] && @messages[uuid][:timeout] < Selfid::Time.now
        end
      end

      Selfid.logger.info "response received for #{uuid}"
      return @messages[uuid][:response]
    ensure
      @inbox.delete(uuid)
      @messages.delete(uuid)
    end

    def send(msg)
      uuid = msg.id
      @mon.synchronize do
        @acks[uuid] = {
          waiting_cond: @mon.new_cond,
          waiting: true,
          timeout: Selfid::Time.now + @timeout,
        }
      end
      @ws.send(msg.to_proto.bytes)
      Selfid.logger.info "waiting for acknowledgement #{uuid}"
      @mon.synchronize do
        @acks[uuid][:waiting_cond].wait_while {@acks[uuid][:waiting]}
      end
    ensure
      @acks.delete(uuid)
    end

    private

      def start
        @listener = loop
      end

      def loop
        @mon.synchronize do
          @acks["authentication"] = {
            waiting_cond: @mon.new_cond,
            waiting: true,
            timeout: Selfid::Time.now + @timeout,
          }
        end

        Thread.new do
          EM.run {
            Selfid.logger.info "starting listener"
            @ws = Faye::WebSocket::Client.new(@url)

            @ws.on :open do |event|
              Selfid.logger.info "websocket connection established"
              authenticate
            end

            @ws.on :message do |event|
              on_message(event)
            rescue TypeError => e
              Selfid.logger.info "invalid array message"
            end

            @ws.on :close do |event|
              Selfid.logger.info "websocket connection closed (#{event.code}) #{event.reason}"
              sleep 2
              Selfid.logger.info "reconnecting..."
              start
            end
          }
        end

        @mon.synchronize do
          @acks["authentication"][:waiting_cond].wait_while {@acks["authentication"][:waiting]}
        end
      ensure
        @acks.delete("authentication")
      end

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
        when :MSG
          Selfid.logger.info "Message #{input.id} received"
          process_incomming_message input
        end
      end

      def process_incomming_message(input)
        message = Selfid::Messages.parse(input, self)

        if @messages.include? message.id
          @messages[message.id][:response] = message
          mark_as_arrived message.id
        else
          Selfid.logger.info "Received async message #{input.id}"
          @inbox[message.id] = message
        end
      rescue StandardError => e
        Selfid.logger.info e
        return
      end

      def authenticate
        Selfid.logger.info "authenticating"
        send_raw Msgproto::Auth.new(
          type: Msgproto::MsgType::AUTH,
          id: "authentication",
          token: @jwt.auth_token,
          device: @device_id,
        )
      end

      def send_raw(msg)
        @ws.send(msg.to_proto.bytes)
      end

      def mark_as_arrived(id)
        return unless @messages.include? id
        @mon.synchronize do
          @messages[id][:waiting] = false
          @messages[id][:waiting_cond].broadcast
        end
      end

      def mark_as_acknowledged(id)
        @mon.synchronize do
          @acks[id][:waiting] = false if @acks.include? id
          @acks[id][:waiting_cond].broadcast
        end
      end

  end
end
