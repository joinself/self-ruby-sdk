# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

# Namespace for classes and modules that handle SelfSDK gem
module SelfSDK
  # Namespace for classes and modules that handle selfsdk-gem public ui
  module Services
    # Input class to request for identities and apps
    class Identity
      # Creates a new identity service.
      # Identity service allows you request information for your connected users / apps.
      #
      # @param [SelfSDK::Client] client http client object.
      #
      # @return [SelfSDK::Services::Identity] facts service.
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
      # @param [String] kid the public key id.
      # @return [Array] with the identity public keys
      def public_key(selfid, kid)
        @client.public_key(selfid, kid).public_key
      end

      # Gets an identity score
      #
      # @param [String] selfid gets the identity details (app/user)
      # @return [integer] the identity score
      def score(selfid)
        res = @client.get("/v1/identities/#{selfid}/score")
        payload = JSON.parse(res.body, symbolize_names: true)
        raise payload[:message] if payload.include? :error_code

        payload[:score]
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