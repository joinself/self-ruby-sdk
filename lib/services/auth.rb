# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

# Namespace for classes and modules that handle SelfSDK gem
module SelfSDK
  # Namespace for classes and modules that handle selfsdk-gem public ui
  module Services
    # Input class to handle authentication requests on self network.
    class Authentication
      # Creates a new authentication service.
      # Authentication service mainly manages authentication requests against self
      # users wanting to authenticate on your app.
      #
      # @param messaging [SelfSDK::Messaging] messaging object.
      # @param client [SelfSDK::Client] http client object.
      #
      # @return [SelfSDK::Services::Authentication] authentication service.
      def initialize(requester)
        @requester = requester
      end

      # Sends an authentication request to the specified selfid.
      # An authentication requests allows your users to authenticate on your app using
      # a secure self app.
      #
      # @overload request(selfid, opts = {}, &block)
      #  @param [String] selfid the receiver of the authentication request.
      #  @param [Hash] opts the options to authenticate.
      #  @option opts [String] :cid The unique identifier of the authentication request.
      #  @option opts [Array] :facts array of facts to be requested
      #  @yield [request] Invokes the block with an authentication response for each result.
      #  @return [String, String] conversation id or encoded body.
      #
      # @overload request(selfid, opts = {})
      #  @param [String] selfid the receiver of the authentication request.
      #  @param [Hash] opts the options to authenticate.
      #  @option [Boolean] :async if the request is asynchronous.
      #  @option opts [String] :cid The unique identifier of the authentication request.
      #  @option opts [Array] :facts array of facts to be requested
      #  @return [String, String] conversation id or encoded body.
      def request(selfid, opts = {}, &block)
        opts[:auth] = true
        facts = opts.fetch(:facts, [])

        @requester.request(selfid, facts, opts, &block)
      end

      # Adds an observer for a fact response
      # Whenever you receive a fact response registered observers will receive a notification.
      #
      #  @yield [request] Invokes the block with a fact response message.
      def subscribe(&block)
        @requester.subscribe(true, &block)
      end

      # Generates a QR code so users can authenticate to your app.
      #
      # @option opts [String] :selfid the user selfid you want to authenticate.
      # @option opts [String] :cid The unique identifier of the authentication request.
      #
      # @return [String, String] conversation id or encoded body.
      def generate_qr(opts = {})
        opts[:auth] = true
        facts = opts.fetch(:facts, [])

        @requester.generate_qr(facts, opts)
      end

      # Generates a deep link to authenticate with self app.
      #
      # @param callback [String] the callback identifier you'll be redirected to if the app is not installed.
      # @option opts [String] :selfid the user selfid you want to authenticate.
      # @option opts [String] :cid The unique identifier of the authentication request.
      #
      # @return [String, String] conversation id or encoded body.
      def generate_deep_link(callback, opts = {})
        opts[:auth] = true
        facts = opts.fetch(:facts, [])

        @requester.generate_deep_link(facts, callback, opts)
      end

      private

      # Checks if the given input is an accepted authentication request.
      #
      # @param response [string] the response to an authentication request from self-api.
      # @return [Hash] Details response.
      #   * :accepted [Boolean] a bool describing if authentication is accepted or not.
      #   * :uuid [String] the request identifier.
      def authenticated?(response)
        Authenticated.new(valid_payload(response))
      end

      # checks if a payload is valid or not.
      #
      # @param response [string] the response to an authentication request from self-api.
      def valid_payload(response)
        parse_payload(response)
      rescue StandardError => e
        SelfSDK.logger.error e
        uuid = ""
        uuid = response[:cid] unless response.nil?
        SelfSDK.logger.error "error checking authentication for #{uuid} : #{e.message}"
        p e.backtrace
        nil
      end

      def parse_payload(response)
        jws = @client.jwt.parse(response)
        return unless jws.include? :payload

        payload = JSON.parse(@client.jwt.decode(jws[:payload]), symbolize_names: true)
        return if payload.nil?

        identity = @client.entity(payload[:sub])
        return if identity.nil?

        payload
      end
    end
  end
end
