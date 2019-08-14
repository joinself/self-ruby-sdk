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
  # @attr_reader [Types] api_key the api key for the current app.
  # @attr_reader [Types] auth_token .... ???''
  class App
    attr_reader :self_url, :app_id, :api_key, :auth_token

    # Initializes a Selfid App
    #
    # @param app_id [string] the app id.
    # @param api_key [string] the app api key provided by developer portal.
    # @param auth_token [string] .... ?????
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :self_url The self provider url.
    def initialize(app_id, api_key, auth_token, opts = {})
      @app_id = app_id
      @api_key = api_key
      @auth_token = auth_token
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
        callback: callback_url,
        url: @self_url,
        self_id: @app_id,
        user_id: user_id,
        created: Time.now.utc,
        expires: Time.now.utc + 3600,
        UUID: uuid,
      }.to_json

      signature = sign("#{encode(default_jws_header)}.#{encode(payload)}")
      jws = {
        payload: encode(payload),
        protected: encode(default_jws_header),
        signature: encode(signature)
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
      req = Net::HTTP::Post.new("/auth",
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
      Base64.encode64(input)
    end

    # Signs the given input with the configured Ed25519 key.
    #
    # @param input [string] the string to be signed.
    def sign(input)
      signing_key = Ed25519::SigningKey.new(@api_key)
      signing_key.sign(input)
    end
  end
end
