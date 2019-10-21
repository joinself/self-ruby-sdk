module Selfid
  module Messages
    class Base
      attr_accessor :from, :from_device, :to, :to_device, :expires, :id, :fields, :typ, :payload, :status, :input

      def initialize(messaging)
        @client = messaging.client
        @jwt = messaging.jwt
        @messaging = messaging
        @device_id = "1"
      end

      def request
        Selfid.logger.info "synchronously requesting information to #{@to}:#{@to_device}"
        @messaging.send_and_wait_for_response(proto)
      end

      def send
        Selfid.logger.info "asynchronously requesting information to #{@to}:#{@to_device}"
        @messaging.send proto
      end

      protected
        def proto
          raise StandardError "must define this method"
        end

      private
        def get_payload(input)
          jwt = JSON.parse(@jwt.decode(input.ciphertext), symbolize_names: true)
          payload = JSON.parse(@jwt.decode(jwt[:payload]), symbolize_names: true)
          @from = payload[:iss]
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
