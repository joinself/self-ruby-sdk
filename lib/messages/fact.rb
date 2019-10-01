module Selfid
  module Messages
    class Fact
      attr_accessor :name, :value, :verified, :origin, :source

      def initialize(key, input, from, messaging)
        jwt = JSON.parse(messaging.jwt.decode(input), symbolize_names: true)
        payload = JSON.parse(messaging.jwt.decode(jwt[:payload]), symbolize_names: true)
        @origin = payload[:iss]
        @source = payload[:source]
        @name = key
        @value = payload[key.to_sym]

        k = messaging.client.public_keys(@origin).first[:key]
        raise StandardError("invalid signature") unless messaging.jwt.verify(jwt, k)
        @verified = (@origin != from)
      end
    end
  end
end
