# frozen_string_literal: true

module Selfid
  module Services
    class Identity
      def initialize(client)
        @client = client
      end

      # Gets an identity details
      #
      # @param self_id [string] identity SelfID
      def user(self_id)
        @client.identity(self_id)
      end

      # Gets an app defails
      #
      # @param self_id [string] app SelfID
      def app(self_id)
        @client.app(self_id)
      end

      # Gets an app/identity defails
      #
      # @param self_id [string] app/identity SelfID
      def get(self_id)
        @client.entity(self_id)
      end

      # Gets selfid registered devices
      #
      # @param self_id [string] identity/app selfID
      def devices(self_id)
        @client.devices(self_id)
      end
    end
  end
end