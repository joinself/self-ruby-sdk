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

      # Gets registered devices for a self identity
      #
      # @param [String] selfid identity/app selfID
      # @return [Array] array of device ids for the given selfid
      def devices(selfid)
        @client.devices(selfid)
      end

      # Gets an identity public keys
      #
      # @param [String] selfid gets the identity details (app/user)
      # @return [Array] with the identity public keys
      def public_keys(selfid)
        @client.public_keys(selfid)
      end

      # Gets an app/identity details
      #
      # @param [String] selfid gets the identity details (app/user)
      # @return [Hash] with identity details
      def get(selfid)
        @client.entity(selfid)
      end
    end
  end
end