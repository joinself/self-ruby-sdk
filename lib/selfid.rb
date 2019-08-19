# frozen_string_literal: true

require 'securerandom'
require "ed25519"
require 'json'
require 'base64'
require 'net/http'

# Namespace for classes and modules that handle Self interactions.
module Selfid
  # Abstract base class for CLI utilities. Provides some helper methods for
  # the option parser
  #
  # @attr_reader [Types] self_url the self provider url.
  # @attr_reader [Types] app_id the identifier of the current app.
  # @attr_reader [Types] app_key the api key for the current app.
  class App
    attr_reader :self_url, :app_id, :app_key

    # Initializes a Selfid App
    #
    # @param app_id [string] the app id.
    # @param app_key [string] the app api key provided by developer portal.
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :self_url The self provider url.
    def initialize(app_id, app_key, opts = {})
      @app_id = app_id
      @app_key = app_key
      @self_url = opts.fetch(:self_url, "https://api.selfid.net")
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
        aud: @self_url,
        isi: @app_id,
        sub: user_id,
        # iat: Time.now.utc,
        # exp: Time.now.utc + 3600,
        jti: uuid,
      }.to_json

      signature = sign("#{encode(default_jws_header)}.#{encode(payload)}")
      jws = {
        payload: encode(payload),
        protected: encode(default_jws_header),
        signature: signature
      }.to_json

      auth jws
      uuid
    end

    private

    # Sends an auth http request to self-api.
    #
    # @param body [string] the payload to be sent as body of request.
    def auth(body)
      uri = URI(@self_url)
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Post.new("/v1/auth",
                                'Content-Type' => 'application/json',
                                'Authorization' => "Bearer #{auth_token}")
      req.body = body
      res = http.request(req)
      raise 'An error has occured' if res.code != "200"
    rescue StandardError => e
      puts "failed #{e}"
      {}
    end

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

    # Signs the given input with the configured Ed25519 key.
    #
    # @param input [string] the string to be signed.
    def sign(input)
      signing_key = Ed25519::SigningKey.new(Base64.decode64(@app_key))
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
