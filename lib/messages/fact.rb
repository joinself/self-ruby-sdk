# frozen_string_literal: true

module Selfid
  module Messages
    class Fact
      attr_accessor :name, :value, :verified, :origin, :source, :operator, :result

      def initialize(messaging)
        @messaging = messaging
      end

      def parse(key, input, from)
        jwt = JSON.parse(@messaging.jwt.decode(input), symbolize_names: true)
        payload = JSON.parse(@messaging.jwt.decode(jwt[:payload]), symbolize_names: true)
        @origin = payload[:iss]
        @source = payload[:source]
        @name = key
        @value = payload[field_map(key.to_sym)]
        @result = payload[:result]
        @verified = valid_signature?(jwt, from)
      end

      def valid_signature?(jwt, _from)
        k = @messaging.client.public_keys(@origin).first[:key]
        raise StandardError("invalid signature") unless @messaging.jwt.verify(jwt, k)

        true
        # return @origin != from
      end

      def signed
        @messaging.jwt.encode(@messaging.jwt.prepare(
                                iss: @origin,
                                source: @source,
                                field: @name,
                                value: @value,
                                result: @result,
                              ))

      protected
      
          def field_map(key)
            {name: :name, email: :email_address}[key]
          end

      end
    end
  end
end
