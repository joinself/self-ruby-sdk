# frozen_string_literal: true

# Namespace for classes and modules that handle Selfid gem
module Selfid
  # Namespace for classes and modules that handle selfid-gem public ui
  module Services
    # Input class to interact with self network messaging.
    class Messaging
      # TODO : we should try to remove this accessor.
      # @attr_accessor [Selfid::Messaging] internal messaging client.
      attr_accessor :client

      # Creates a new messaging service.
      # Messaging service basically allows you to subscribe to certain types of messages,
      # and manage who can send you messages or not.
      #
      # @param client [Selfid::Messaging] messaging object.
      #
      # @return [Selfid::Services::Messaging] authentication service.
      def initialize(client)
        @client = client
      end

      # Subscribes to a specific message type and attaches the given observer
      # which will be executed when a meeting criteria message is received.
      #
      # @param [String] type message type (ex: Selfid::Messages::AuthenticationResp.MSG_TYPE
      # @yield [Selfid::Messages::Message] receives incoming message.
      def subscribe(type, &block)
        @client.type_observer[type] = block
      end

      # Permits incoming messages from the a identity.
      #
      # @param [String] selfid to be allowed.
      # @return [Boolean] success / failure
      def permit_connection(selfid)
        acl.allow selfid
      end

      # Lists app allowed connections.
      # @return [Array] array of self ids allowed to connect to your app.
      def allowed_connections
        acl.list
      end

      # Revokes incoming messages from the given identity.
      #
      # @param [String] selfid to be denied
      # @return [Boolean] success / failure
      def revoke_connection(selfid)
        acl.deny selfid
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

      private

      def acl
        @acl ||= ACL.new(@client)
      end
    end
  end
end