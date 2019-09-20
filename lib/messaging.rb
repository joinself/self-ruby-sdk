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

    def initialize(url, jwt)
      @mon = Monitor.new
      # general conventions is device id on apps is always 1
      @url = url
      @device_id = "1"
      @messages = {}
      @jwt = jwt
      # start

    end

    def start
      @listener = loop
    end

    def stop
      @listener.stop
    end

    def request_information(recipient, facts)
      uuid = SecureRandom.uuid
      Selfid.logger.info "requesting information #{uuid}"
      @mon.synchronize do
        @messages[uuid] = {
          arrived_cond: @mon.new_cond,
          arrived: true,
          body: {
            isi: @jwt.id,
            sub: recipient,
            iat: Time.now.utc.strftime('%FT%TZ'),
            exp: (Time.now.utc + 3600).strftime('%FT%TZ'),
            jti: uuid,
            fields: facts,
          }
        }
        body = @jwt.decode(@messages[uuid][:body].to_json, padding: false)
        send(uuid, recipient, body)

        @mon.synchronize do
          @messages[uuid][:arrived_cond].wait_while {@messages[uuid][:arrived]}
        end
      end

      return @messages[uuid][:response]
    ensure
      @messages.delete(uuid)
    end

    def acl(payload)
      # Authenticate the current user
      msg = Msgproto::AccessControlList.new(
        type: Msgproto::MsgType::ACL,
        id: SecureRandom.uuid,
        command: Msgproto::ACLCommand::PERMIT,
        payload: payload,
      )

      Selfid.logger.info msg.to_json
      require 'pry'; binding.pry
      @ws.send(msg.to_proto.bytes)
    end

    private

    def loop
      Thread.new do
        EM.run {
          Selfid.logger.info "starting listener"
          @ws = Faye::WebSocket::Client.new(@url)

          @ws.on :open do |event|
            on_start
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
    end

    def on_message(event)
      Selfid.logger.info "processing input message"
      input = Msgproto::Message.decode(event.data.pack('c*'))
      case input.type
      when :ERR
        require 'pry'; binding.pry
        Selfid.logger.info "error #{input.sender} on #{input.id}"
        mark_as_arrived(input.id)
      when :ACK
        Selfid.logger.info "Acknowledged #{input.id}"
      when :MSG
        process_message input
      end
    end

    def process_message(input)
      payload = JSON.parse(@jwt.decode(input[:payload]), symbolize_names: true)
      require 'pry'; binding.pry
      return unless @messages.include? payload[:jti]

      @messages[input[:jti]][:response] = input
      mark_as_arrived input[:jti]
    end

    def on_start
      Selfid.logger.info "websocket connection opened"

      # Authenticate the current user
      msg = Msgproto::Auth.new(
        type: Msgproto::MsgType::AUTH,
        id: @jwt.id,
        token: @jwt.auth_token,
        device: @device_id,
      )

      Selfid.logger.info msg.to_json
      @ws.send(msg.to_proto.bytes)
    end

    def send(uuid, recipient, body)
      # Authenticate the current user
      msg = Msgproto::Message.new(
        type: Msgproto::MsgType::MSG,
        id: uuid,
        sender: "#{@jwt.id}:#{@device_id}",
        recipient: recipient,
        ciphertext: body,
      )

      Selfid.logger.info msg.to_json
      sleep 2
      @ws.send(msg.to_proto.bytes)
    end

    def mark_as_arrived(id)
      @messages[id][:arrived] = false
      @mon.synchronize do
        @messages[id][:arrived_cond].broadcast
      end
    end

  end
end
