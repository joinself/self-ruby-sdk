# frozen_string_literal: true

require_relative 'base'
require_relative '../ntptime'

module Selfid
  module Messages
    class AuthenticationReq < Base
      MSG_TYPE = "authentication_req"

      def initialize(messaging)
        @typ = MSG_TYPE
        super
      end

      def populate(selfid, opts)
        @id = SecureRandom.uuid
        @from = @client.jwt.id
        @to = selfid

        @id = opts[:cid] if opts.include?(:cid)
        @description = opts.include?(:description) ? opts[:description] : nil

        @to_device = @client.devices(selfid).first
      end


      def parse(input)
        @input = input
        @typ = MSG_TYPE
        @payload = get_payload input
        @id = payload[:cid]
        @from = payload[:iss]
        @to = payload[:sub]
        @from_device = payload[:device_id]
        @expires = payload[:exp]
        @status = payload[:status]
      end

      def body
        { typ: MSG_TYPE,
          iss: @jwt.id,
          sub: @to,
          aud: @to,
          iat: Selfid::Time.now.strftime('%FT%TZ'),
          exp: (Selfid::Time.now + 3600).strftime('%FT%TZ'),
          cid: @id,
          jti: SecureRandom.uuid }
      end

      protected

      def proto
        Msgproto::Message.new(type: Msgproto::MsgType::MSG,
                              sender: "#{@jwt.id}:#{@messaging.device_id}",
                              id: @id,
                              recipient: "#{@to}:#{@to_device}",
                              ciphertext: @jwt.prepare(body))
      end
    end
  end
end
