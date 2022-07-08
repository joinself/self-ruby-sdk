# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'self_msgproto'
require_relative 'base'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class ConnectionRequest < Base
      MSG_TYPE = "identities.connections.req"
      DEFAULT_EXP_TIMEOUT = 9000

      attr_accessor :facts, :options, :auth

      def initialize(messaging)
        @typ = MSG_TYPE
        super
      end

      def populate(selfid, opts)
        @id = SecureRandom.uuid
        @from = @client.jwt.id
        @to = selfid
        @exp_timeout = opts.fetch(:exp_timeout, DEFAULT_EXP_TIMEOUT)
      end

      def parse(input, envelope=nil)
        super
        @typ = MSG_TYPE
        @body = @payload[:msg]
      end

      def body
        {
          typ: MSG_TYPE,
          iss: @jwt.id,
          aud: @to,
          sub: @to,
          iat: SelfSDK::Time.now.strftime('%FT%TZ'),
          exp: (SelfSDK::Time.now + @exp_timeout).strftime('%FT%TZ'),
          jti: SecureRandom.uuid,
          require_confirmation: true,
        }
      end

      protected

      def proto(to_device)
        @to_device = to_device
        recipient = "#{@to}:#{@to_device}"
        ciphertext = encrypt_message(@jwt.prepare(body), [{id: @to, device_id: @to_device}])

        m = SelfMsg::Message.new
        m.id = @id
        m.sender = "#{@jwt.id}:#{@messaging.device_id}"
        m.recipient = recipient
        m.ciphertext = ciphertext
        m
      end
    end
  end
end
