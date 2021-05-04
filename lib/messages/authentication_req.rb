# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'base'
require_relative '../ntptime'
require_relative 'authentication_message'

module SelfSDK
  module Messages
    class AuthenticationReq < AuthenticationMessage
      MSG_TYPE = "identities.authenticate.req"
      DEFAULT_EXP_TIMEOUT = 300

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
        @exp_timeout = opts.fetch(:exp_timeout, DEFAULT_EXP_TIMEOUT)
      end

      def body
        { typ: MSG_TYPE,
          iss: @jwt.id,
          sub: @to,
          aud: @to,
          iat: SelfSDK::Time.now.strftime('%FT%TZ'),
          exp: (SelfSDK::Time.now + @exp_timeout).strftime('%FT%TZ'),
          cid: @id,
          jti: SecureRandom.uuid }
      end

      protected

      def proto(to_device)
        Msgproto::Message.new(type: Msgproto::MsgType::MSG,
                              sender: "#{@jwt.id}:#{@messaging.device_id}",
                              id: SecureRandom.uuid,
                              recipient: "#{@to}:#{to_device}",
                              ciphertext: encrypt_message(@jwt.prepare(body), @to, to_device))
      end

    end
  end
end
