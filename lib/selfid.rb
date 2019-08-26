# frozen_string_literal: true

require 'securerandom'
require "ed25519"
require 'json'
require 'base64'
require 'net/http'
require_relative 'client'

# Namespace for classes and modules that handle Self interactions.
module Selfid
  # Abstract base class for CLI utilities. Provides some helper methods for
  # the option parser
  #
  # @attr_reader [Types] app_id the identifier of the current app.
  # @attr_reader [Types] app_key the api key for the current app.
  class App
    attr_reader :app_id, :app_key, :client

    # Initializes a Selfid App
    #
    # @param app_id [string] the app id.
    # @param app_key [string] the app api key provided by developer portal.
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :self_url The self provider url.
    def initialize(app_id, app_key, opts = {})
      @app_id = app_id
      @app_key = app_key
      url = opts.fetch(:self_url, "https://api.selfid.net")
      @client = Selfid::RestClient.new(url, auth_token)
    end

    # Sends an authentication request to the specified user_id.
    #
    # @param user_id [string] the receiver of the authentication request.
    # @param callback_url [string] the callback url where self will send authentication response.
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :uuid The unique identifier of the authentication request.
    def authenticate(user_id, callback_url, opts = {})
      uuid = opts.fetch(:uuid, SecureRandom.uuid)
      payload = {
        iss: callback_url,
        aud: @client.self_url,
        isi: @app_id,
        sub: user_id,
        iat: Time.now.utc.strftime('%FT%TZ'),
        exp: (Time.now.utc + 3600).strftime('%FT%TZ'),
        jti: uuid,
      }.to_json

      signature = sign("#{encode(default_jws_header)}.#{encode(payload)}")
      jws = {
        payload: encode(payload),
        protected: encode(default_jws_header),
        signature: signature
      }.to_json

      @client.auth jws
      uuid
    end

    # Checks if the given input is an accepted authentication request.
    #
    # @param response [string] the response to an authentication request from self-api.
    # @return [Hash] Details response.
    #   * :accepted [Boolean] a bool describing if authentication is accepted or not.
    #   * :uuid [String] the request identifier.
    def authenticated?(response)
      res = { accepted: false }
      jws = JSON.parse(response, symbolize_names: true)
      payload = JSON.parse(decode(jws[:payload]), symbolize_names: true)
      res[:uuid] = payload[:jti]
      res[:selfid] = payload[:aud]
      identity = identity(payload[:sub])
      return res if identity.nil?

      identity[:public_keys].each do |key|
        verify_key = Ed25519::VerifyKey.new(decode(key[:key]))
        if verify_key.verify(decode(jws[:signature]), "#{jws[:protected]}.#{jws[:payload]}")
          res[:accepted] = (payload[:status] == "accepted")
          return res
        end
      end
      res
    rescue StandardError
      res
    end

    def identity(id)
      @client.identity(id)
    end

    private

    # The default jws header
    def default_jws_header
      { typ: "EdDSA" }.to_json
    end

    # Encodes the input with base64
    #
    # @param input [string] the string to be encoded.
    def encode(input)
      Base64.strict_encode64(input).gsub("=", "")
    end

    # Base64 decodes the input string
    #
    # @param input [string] the string to be decoded.
    def decode(input)
      Base64.decode64(input)
    end

    # Signs the given input with the configured Ed25519 key.
    #
    # @param input [string] the string to be signed.
    def sign(input)
      signing_key = Ed25519::SigningKey.new(decode(@app_key))
      encode(signing_key.sign(input))
    end

    # Generates the auth_token based on the app's private key.
    def auth_token
      @auth_token ||= begin
        payload = encode({ "alg": "EdDSA", "typ": "JWT" }.to_json) + "." + encode({ iss: @app_id }.to_json)
        signature = sign(payload)
        "#{payload}.#{signature}"
      end
    end
  end
end
