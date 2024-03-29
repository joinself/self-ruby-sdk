# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

# Namespace for classes and modules that handle SelfSDK gem
module SelfSDK
  # Namespace for classes and modules that handle selfsdk-gem public ui
  module Services
    # Input class to interact with self network messaging.
    class Messaging
      # TODO : we should try to remove this accessor.
      # @attr_accessor [SelfSDK::Messaging] internal messaging client.
      attr_accessor :client

      # Creates a new messaging service.
      # Messaging service basically allows you to subscribe to certain types of messages,
      # and manage who can send you messages or not.
      #
      # @param client [SelfSDK::Messaging] messaging object.
      #
      # @return [SelfSDK::Services::Messaging] authentication service.
      def initialize(client)
        @client = client
      end

      # Subscribes to a specific message type and attaches the given observer
      # which will be executed when a meeting criteria message is received.
      #
      # @param [String] type message type (ex: SelfSDK::Messages::FactRequest.MSG_TYPE
      # @yield [SelfSDK::Messages::Message] receives incoming message.
      def subscribe(type, &block)
        @client.subscribe(type, &block)
      end

      # Gets the device id for the authenticated app.
      #
      # @return [String] device_id of the running app.
      def device_id
        @client.device_id
      end

      # Get the observer by uuid
      #
      # @param [String] cid conversation id
      def observer(cid)
        @client.uuid_observer[cid]
      end

      # Send custom mmessage
      #
      # @param recipients [String|array] recipient for the message
      # @param type [string] message type
      # @param request [hash] message to be sent
      def send(recipients, request)
        request[:jti] = SecureRandom.uuid unless request.include?(:jti)
        request[:iss] = @client.jwt.id
        request[:iat] = SelfSDK::Time.now.strftime('%FT%TZ')
        request[:exp] = (SelfSDK::Time.now + 300).strftime('%FT%TZ')        
        request[:cid] = SecureRandom.uuid unless request.include?(:cid)

        @client.send_custom(recipients, request)
        request
      end

      def notify(recipient, message)
        send recipient, {
            typ: 'identities.notify',
            description: message
          }
      end

      private
    end
  end
end