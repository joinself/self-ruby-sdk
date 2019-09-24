# frozen_string_literal: true

require 'json'
require 'monitor'
require 'faye/websocket'
require_relative 'proto/auth_pb'
require_relative 'proto/message_pb'
require_relative 'proto/msgtype_pb'
require_relative 'proto/acl_pb'
require_relative 'proto/aclcommand_pb'

module Selfid
  class MessagingClient
    attr_reader :inbox

    def initialize(url, jwt)
      @inbox = []
      @mon = Monitor.new
      # general conventions is device id on apps is always 1
      @url = url
      @device_id = "1"
      @messages = {}
      @acks = {}
      @jwt = jwt
      start
    end

    def start
      @listener = loop
    end

    def stop
      @listener.stop unles listener.nil?
    end

    def request_information(recipient, facts, type: :sync)
      uuid = SecureRandom.uuid
      msg = Msgproto::Message.new(
        type: Msgproto::MsgType::MSG,
        id: uuid,
        sender: "#{@jwt.id}:#{@device_id}",
        # TODO(adriacidre) remove hardcoded device id
        recipient: "#{recipient}:1",
        ciphertext: @jwt.encode({
            isi: @jwt.id,
            sub: recipient,
            iat: Time.now.utc.strftime('%FT%TZ'),
            exp: (Time.now.utc + 3600).strftime('%FT%TZ'),
            jti: uuid,
            fields: facts,
          }.to_json),
      )
      return send_and_wait_for_response(msg) if type == :sync
      send msg
    end

    def acl(payload)
      send Msgproto::AccessControlList.new(
        type: Msgproto::MsgType::ACL,
        id: SecureRandom.uuid,
        command: Msgproto::ACLCommand::PERMIT,
        payload: payload,
      )
    end

    private

      def loop
        @mon.synchronize do
          @acks["authentication"] = {
            waiting_cond: @mon.new_cond,
            waiting: true
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
          process_message input
        end
      end

      def process_message(input)
        payload = JSON.parse(@jwt.decode(input[:payload]), symbolize_names: true)
        if @messages.include? payload[:jti]
          @messages[input[:jti]][:response] = input
          mark_as_arrived input[:jti]
        else
          Selfid.logger.info "Received async message #{input.id}"
          @inbox[input[:jti]] = input
        end
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

      def send_and_wait_for_response(msg)
        uuid = msg.id

        Selfid.logger.info "sending #{uuid}"
        @mon.synchronize do
          @messages[uuid] = {
            waiting_cond: @mon.new_cond,
            waiting: true,
          }
        end
        send msg

        Selfid.logger.info "waiting for client to respond #{uuid}"
        @mon.synchronize do
          @messages[uuid][:waiting_cond].wait_while {@messages[uuid][:waiting]}
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
            waiting: true
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
