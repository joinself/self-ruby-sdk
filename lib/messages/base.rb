# frozen_string_literal: true

module SelfSDK
  module Messages
    class Base
      attr_accessor :from, :from_device, :to, :to_device, :expires, :id,
                    :fields, :typ, :payload, :status, :input, :intermediary,
                    :description, :sub, :exp_timeout

      def initialize(messaging)
        @client = messaging.client
        @jwt = @client.jwt
        @messaging = messaging
        @device_id = "1"
      end

      def request
        res = @messaging.send_and_wait_for_response(proto, self)
        SelfSDK.logger.info "synchronously messaging to #{@to}:#{@to_device}"
        res
      end

      def send_message
        res = @messaging.send_message proto
        SelfSDK.logger.info "asynchronously requested information to #{@to}:#{@to_device}"
        res
      end

      def unauthorized?
        status == "unauthorized"
      end

      def rejected?
        status == "rejected"
      end

      def accepted?
        status == "accepted"
      end

      def errored?
        status == "errored"
      end

      def validate!(original)
        unless original.nil?
          raise ::StandardError.new("bad response audience") if @audience != original.from
          if original.intermediary.nil?
            raise ::StandardError.new("bad issuer") if @from != original.to
          else
            raise ::StandardError.new("bad issuer") if @from != original.intermediary
          end
        end
        raise ::StandardError.new("expired message") if @expires < SelfSDK::Time.now
        raise ::StandardError.new("issued too soon") if @issued > SelfSDK::Time.now
      end

      protected

      def proto
        raise ::StandardError.new("must define this method")
      end

      private

      def get_payload(input)
        body = if input.is_a? String
                 input
               else
                 input.ciphertext
               end

        jwt = JSON.parse(body, symbolize_names: true)
        payload = JSON.parse(@jwt.decode(jwt[:payload]), symbolize_names: true)
        header = JSON.parse(@jwt.decode(jwt[:protected]), symbolize_names: true)
        @from = payload[:iss]
        verify! jwt, header[:kid]
        payload
      end

      def verify!(input, kid)
        k = @client.public_key(@from, kid).raw_public_key
        return if @jwt.verify(input, k)

        SelfSDK.logger.info "skipping message, invalid signature"
        raise ::StandardError.new("invalid signature on incoming message")
      end
    end
  end
end
