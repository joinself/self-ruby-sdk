# frozen_string_literal: true

module Selfid
  module Messages
    class Base
      attr_accessor :from, :from_device, :to, :to_device, :expires, :id,
                    :fields, :typ, :payload, :status, :input, :intermediary,
                    :description

      def initialize(messaging)
        @client = messaging.client
        @jwt = @client.jwt
        @messaging = messaging
        @device_id = "1"
      end

      def request
        Selfid.logger.info "synchronously requesting information to #{@to}:#{@to_device}"
        @messaging.send_and_wait_for_response(proto)
      end

      def send_message
        Selfid.logger.info "asynchronously requesting information to #{@to}:#{@to_device}"
        @messaging.send_message proto
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
        @from = payload[:iss]
        verify! jwt
        payload
      end

      def verify!(jwt)
        k = @client.public_keys(@from).first[:key]
        return if @jwt.verify(jwt, k)

        Selfid.logger.info "skipping message, invalid signature"
        raise ::StandardError.new("invalid signature on incoming message")
      end
    end
  end
end
