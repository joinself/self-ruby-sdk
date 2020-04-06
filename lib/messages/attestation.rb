# frozen_string_literal: true

module Selfid
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
        @verified = valid_signature?(attestation)
        @expected_value = payload[:expected_value]
        @operator = payload[:operator]
        @fact_name = name.to_s
        unless payload[name].nil?
          @value = payload[name]
        end
      end

      def valid_signature?(body)
        k = @messaging.client.public_keys(@origin).first[:key]
        raise StandardError("invalid signature") unless @messaging.jwt.verify(body, k)

        true
        # return @origin != from
      end

      def signed
        o = {
            sub: @to,
            iss: @origin,
            source: @source,
            fact: @fact_name,
            expected_value: @expected_value,
            operator: @operator,
        }
        o[:aud] = @audience if not @audience.nil?
        o[@fact_name.to_sym] = @value
        @messaging.jwt.signed(o)
      end
    end
  end
end
