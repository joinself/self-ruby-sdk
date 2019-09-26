module Selfid
  module Messages
    class Base
      attr_accessor :from, :to, :to_device, :expires, :id, :fields, :typ, :payload

      def initialize(client, jwt, messaging)
        @client = client
        @jwt = jwt
        @messaging = messaging
        @device_id = "1"
      end

      private
        def get_payload(input)
          jwt = JSON.parse(@jwt.decode(input.ciphertext), symbolize_names: true)
          payload = JSON.parse(@jwt.decode(jwt[:payload]), symbolize_names: true)
          @from = payload[:isi]
          verify! jwt
          payload
        end

        def verify!(jwt)
          k = @client.public_keys(@from).first[:key]
          if !@jwt.verify(jwt, k)
            Selfid.logger.info "skipping message, invalid signature"
            raise StandardError "invalid signature on incoming message"
          end
        end
    end
  end
end
