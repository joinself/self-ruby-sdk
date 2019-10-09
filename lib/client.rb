# frozen_string_literal: true

require 'httparty'

module Selfid
  class RestClient
    attr_reader :self_url

    # RestClient initializer
    #
    # @param url [string] self-messaging url
    # @param token [string] jwt token identifying the authenticated user
    def initialize(url, token)
      @self_url = url
      @token = token
    end

    # Sends an auth http request to self-api.
    #
    # @param body [string] the payload to be sent as body of request.
    def auth(body)
      res = post("/v1/auth", body)
      return unless res.code != 200

      body = JSON.parse(res.body, symbolize_names: true)
      Selfid.logger.error "auth response : #{body[:message]}"
      raise body[:message]
    end

    # Get identity / app details
    #
    # @param id [string] identity id.
    def identity(id)
      if id.length == 11
        res = get "/v1/identities/#{id}"
      else
        res = get "/v1/apps/#{id}"
      end
      body = JSON.parse(res.body, symbolize_names: true)
      if res.code != 200
        Selfid.logger.error "identity response : #{body[:message]}"
        raise body[:message]
      end
      body
    end

    # Lists all devices assigned to the given identity
    #
    # @param id [string] identity id
    def devices(id)
      res = get "/v1/identities/#{id}/devices"
      body = JSON.parse(res.body, symbolize_names: true)
      if res.code != 200
        Selfid.logger.error "identity response : #{body[:message]}"
        raise "you need connection permissions"
      end
      body
    end

    # Lists all public keys stored on self for the given ID
    #
    # @param id [string] identity id
    def public_keys(id)
      i = identity(id)
      i[:public_keys]
    end

    private

      def get(endpoint)
        HTTParty.get("#{@self_url}#{endpoint}", headers: {
                       'Content-Type' => 'application/json',
                       'Authorization' => "Bearer #{@token}"
                     })
      end

      def post(endpoint, body)
        HTTParty.post("#{@self_url}#{endpoint}",
                      headers: {
                        'Content-Type' => 'application/json',
                        'Authorization' => "Bearer #{@token}"
                      },
                      body: body)
      end
  end
end
