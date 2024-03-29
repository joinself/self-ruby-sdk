# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

module SelfSDK
  module Messages

    PRIORITY_VISIBLE   = 1
    PRIORITY_INVISIBLE = 2

    class Base
      attr_accessor :from, :from_device, :to, :to_device, :expires, :id,
                    :fields, :typ, :payload, :status, :input, :intermediary,
                    :description, :sub, :exp_timeout

      def initialize(messaging)
        @intermediary = nil
        @client = messaging.client
        @jwt = @client.jwt
        @messaging = messaging
        @device_id = "1"
      end

      def request
        check_credits!
        msgs = []
        devices.each do |d|
          msgs << proto(d)
        end
        current_devices.each do |d|
          if d != @messaging.device_id
            msgs << proto(d)
          end
        end
        SelfSDK.logger.info "synchronously messaging to #{@to}"
        res = @messaging.send_and_wait_for_response(msgs, self)
        res
      end

      def send_message(device_id = nil)
        check_credits!
        dds = devices
        dds = [device_id] if device_id
        res = []
        dds.each do |d|
          res << @messaging.send_message(proto(d))
          SelfSDK.logger.info "asynchronously requested information to #{@to}:#{d}"
        end
        res.first
      end

      def encrypt_message(message, recipients)
        @messaging.encryption_client.encrypt(message, recipients)
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
        raise ::StandardError.new("issued too soon") if @issued.round > (SelfSDK::Time.now + 1).round
      end

      protected

      def proto(to_device)
        raise ::StandardError.new("must define this method")
      end

      def devices
        return @client.devices(@to) if @intermediary.nil?
                  
        @client.devices(@intermediary)
      end

      def current_devices
        @client.devices(@jwt.id)
      end

      def check_credits!
        app = @client.app(@jwt.id)
        raise "Your credits have expired, please log in to the developer portal and top up your account." if app[:paid_actions] == false
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
