# frozen_string_literal: true

module Selfid
  module Messages
    class Fact
      attr_accessor :verified, :origin, :source, :value

      def initialize(messaging)
        @messaging = messaging
      end

      def parse(name, attestation, from)
          payload = JSON.parse(@messaging.jwt.decode(a[:payload]), symbolize_names: true)
          @origin = payload[:iss]
          @source = payload[:source]
          @verified = valid_signature?(attestation, from)

          unless payload[name].nil?
            @value = payload[:name]
          end
      end

      def valid_signature?(jwt, _from)
        k = @messaging.client.public_keys(@origin).first[:key]
        raise StandardError("invalid signature") unless @messaging.jwt.verify(jwt, k)

        true
        # return @origin != from
      end

    end
  end
end
