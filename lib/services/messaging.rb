# frozen_string_literal: true

module Selfid
  module Services
    class Messaging
      attr_accessor :client
      def initialize(client)
        @client = client
      end

      # Adds an observer for a message type
      #
      # @param type [string] message type (ex: Selfid::Messages::AuthenticationResp.MSG_TYPE
      # @param block [block] observer to be executed.
      def subscribe(type, &block)
        @client.type_observer[type] = block
      end

      # Permits incoming messages from the given identity.
      #
      # @param id [string] identity to be allowed
      def permit_connection(id)
        acl.allow id
      end

      # Lists allowed connections.
      def allowed_connections
        acl.list
      end

      # Revokes incoming messages from the given identity.
      #
      # @param id [string] identity to be denied
      def revoke_connection(id)
        acl.deny id
      end

      # Gets the current running app device_id
      def device_id
        @client.device_id
      end

      # Get the observer by uuid
      #
      # @param id [string] uuid of the observer to be retrieved
      def observer(id)
        @client.uuid_observer[id]
      end

      def set_observer(id, &block)
        @client.uuid_observer[id] = block
      end

      private

      def acl
        @acl ||= ACL.new(@client)
      end
    end
  end
end