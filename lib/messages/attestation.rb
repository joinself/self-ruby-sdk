# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative '../ntptime'

module SelfSDK
  module Messages
    class Attestation
      attr_accessor :verified, :origin, :source, :value, :operator, :expected_value, :fact_name, :to, :audience

      def initialize(messaging)
        @messaging = messaging
      end

      def parse(name, attestation)
        payload = JSON.parse(@messaging.jwt.decode(attestation[:payload]), symbolize_names: true)
        @origin = payload[:iss]
        @to = payload[:sub]
        @audience = payload[:aud]
        @source = payload[:source]
        header = JSON.parse(@messaging.jwt.decode(attestation[:protected]), symbolize_names: true)
        @verified = valid_signature?(attestation, header[:kid])
        @expected_value = payload[:expected_value]
        @operator = payload[:operator]
        @fact_name = name.to_s
        unless payload[name].nil?
          @value = payload[name]
        end
      end

      def valid_signature?(body, kid)
        k = @messaging.client.public_key(@origin, kid).raw_public_key
        raise ::StandardError.new("invalid signature") unless @messaging.jwt.verify(body, k)

        true
      end

      def validate!(original)
        raise ::StandardError.new("invalid origin") if @to != original.to
      end

      def signed
        o = {
            sub: @to,
            iss: @origin,
            iat: SelfSDK::Time.now.strftime('%FT%TZ'),
            source: @source,
            fact: @fact_name,
            expected_value: @expected_value,
            operator: @operator,
        }
        o[:aud] = @audience unless @audience.nil?
        o[@fact_name.to_sym] = @value
        @messaging.jwt.signed(o)
      end
    end
  end
end
