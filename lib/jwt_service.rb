# frozen_string_literal: true

require 'base64'
require 'json'

module SelfSDK
  class JwtService
    attr_reader :id, :key, :key_id

    # Jwt initializer
    #
    # @param app_id [string] the app id.
    # @param app_key [string] the app api key provided by developer portal.
    def initialize(app_id, app_key)
      @id = app_id
      parts = app_key.split(':')
      if parts.length > 1
        @key_id = parts[0]
        @key = parts[1]
      else
        @key_id = "1"
        @key = app_key
      end
    end

    # Prepares a jwt object based on an input
    #
    # @param input [string] input to be prepared
    def prepare(input)
      signed(input).to_json
    end

    def signed(input)
      payload = encode(input.to_json)
      {
        payload: payload,
        protected: header,
        signature: sign("#{header}.#{payload}")
      }
    end

    def parse(input)
      JSON.parse(input, symbolize_names: true)
    end

    # Encodes the input with base64
    #
    # @param input [string] the string to be encoded.
    def encode(input)
      Base64.urlsafe_encode64(input, padding: false)
    end

    # Base64 decodes the input string
    #
    # @param input [string] the string to be decoded.
    def decode(input)
      Base64.urlsafe_decode64(input)
    end

    # Signs the given input with the configured Ed25519 key.
    #
    # @param input [string] the string to be signed.
    def sign(input)
      signing_key = Ed25519::SigningKey.new(decode(@key))
      signature = signing_key.sign(input)
      encode(signature)
    end

    def verify(payload, key)
      verify_key = Ed25519::VerifyKey.new(decode(key))
      if verify_key.verify(decode(payload[:signature]), "#{payload[:protected]}.#{payload[:payload]}")
        return true
      end
    rescue StandardError
      false
    end

    # Generates the auth_token based on the app's private key.
    def auth_token
      payload = header + "." + encode({
        jti: SecureRandom.uuid,
        cid: SecureRandom.uuid,
        typ: 'auth.token',
        iat: (SelfSDK::Time.now - 5).to_i,
        exp: (SelfSDK::Time.now + 60).to_i,
        iss: @id,
        sub: @id}.to_json)
      signature = sign(payload)
      "#{payload}.#{signature}"
    end

    private

    def header
      encode({ alg: "EdDSA", typ: "JWT", kid: "#{@key_id}" }.to_json)
    end
  end
end
