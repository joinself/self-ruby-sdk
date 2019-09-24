require 'base64'
require 'json'

module Selfid
  class Jwt
    attr_reader :id, :key

    def initialize(id, key)
      @id = id
      @key = key
    end

    def protected
      encode({ alg: "EdDSA", typ: "JWT" }.to_json)
    end

    def prepare(input)
      payload = encode(input.to_json)
      {
        payload: payload,
        protected: protected,
        signature: sign("#{protected}.#{payload}")
      }.to_json
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
    end

    # Generates the auth_token based on the app's private key.
    def auth_token
      @auth_token ||= begin
        payload = protected + "." + encode({ iss: @id }.to_json)
        signature = sign(payload)
        "#{payload}.#{signature}"
      end
    end

    private


  end
end
