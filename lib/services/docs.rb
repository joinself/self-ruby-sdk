# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

# Namespace for classes and modules that handle SelfSDK gem
module SelfSDK
  # Namespace for classes and modules that handle selfsdk-gem public ui
  module Services
    # Input class to handle document requests on self network.
    class Docs
      attr_accessor :app_id

      # Creates a new docs service.
      # Docs service mainly allows you to send document signature requests.
      #
      # @param messaging [SelfSDK::Messaging] messaging object.
      #
      # @return [SelfSDK::Services::Docs] docs service.
      def initialize(messaging, url)
        @messaging = messaging
        @self_url = url
      end

      # Sends a signature request to the specified user.
      #
      # @param recipient [string] the recipient of the request.
      # @param body [string] the message to be displayed to the user.
      # @param objects [Array] array of objects to be signed. provide an empty array if 
      # you just want the body to be signed.
      # @yield [request] Invokes the given block when a response is received.
      def request_signature(recipient, body, objects, opts = {}, &block)
        jti = SecureRandom.uuid
        req = {
          jti: jti,
          typ: "document.sign.req",
          aud: recipient,
          msg: body,
          objects: [],
        }

        auth_token = @messaging.client.jwt.auth_token
        objects.each do |o|
          req[:objects] << SelfSDK::Chat::FileObject.new(auth_token, @self_url).build_from_data(
            o[:name],
            o[:data],
            o[:mime],
            opts
          ).to_payload
        end

        if block_given?
          @messaging.client.set_observer(OpenStruct.new({
            id: jti,
            to: recipient,
            from: @messaging.client.jwt.id
          }), timeout: 60 * 60 * 10, &block)

          return @messaging.send(recipient, req)
        end

        @messaging.send(recipient, req)
      end

      # Subscribes to all document sign responses.
      #
      # @yield [request] Invokes the given block when a response is received.
      def subscribe(&block)
        @messaging.subscribe(:document_sign_response, &block)
      end
    end
  end
end
