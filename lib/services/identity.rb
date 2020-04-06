# frozen_string_literal: true

# Namespace for classes and modules that handle Selfid gem
module Selfid
  # Namespace for classes and modules that handle selfid-gem public ui
  module Services
    # Input class to request for identities and apps
    class Identity
      # Creates a new identity service.
      # Identity service allows you request information for your connected users / apps.
      #
      # @param [Selfid::Client] client http client object.
      #
      # @return [Selfid::Services::Identity] facts service.
      def initialize(client)
        @client = client
      end

      # Gets user details
      #
      # @param [String] selfid identity SelfID
      # @return [Hash] with user details
      def user(selfid)
        @client.identity(selfid)
      end

      # Gets an the app details
      #
      # @param [string] selfid app SelfID
      # @return [Hash] with app details
      def app(selfid)
        @client.app(selfid)
      end

      # Gets an app/identity details
      #
      # @param [String] selfid gets the identity details (app/user)
      # @return [Hash] with identity details
      def get(selfid)
        @client.entity(selfid)
      end

      # Gets registered devices for a self identity
      #
      # @param [String] selfid identity/app selfID
      # @return [Array] array of device ids for the given selfid
      def devices(selfid)
        @client.devices(selfid)
      end
    end
  end
end