# frozen_string_literal: true

require 'httparty'

module Selfid
  class RestClient
    attr_reader :self_url

    # RestClient initializer
    #
    # @param url [string] self-messaging url
    # @param token [string] jwt token identifying the authenticated user
    def initialize(url, jwt)
      @self_url = url
      @jwt = jwt
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

    # Get identity details
    #
    # @param id [string] identity self_id.
    def identity(id)
      res = get "/v1/identities/#{id}"
      body = JSON.parse(res.body, symbolize_names: true)
      if res.code != 200
        Selfid.logger.error "identity response : #{body[:message]}"
        raise body[:message]
      end
      body
    end

    # Get app details
    #
    # @param id [string] app self_id.
    def app(id)
      res = get "/v1/apps/#{id}"
      body = JSON.parse(res.body, symbolize_names: true)
      if res.code != 200
        Selfid.logger.error "app response : #{body[:message]}"
        raise body[:message]
      end
      body
    end

    # Get app/identity details
    #
    # @param id [string] app/identity self_id.
    def entity(id)
      if id.length == 11
        return identity(id)
      else
        return app(id)
      end
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
                     'Authorization' => "Bearer #{@jwt.auth_token}"
                   })
    end

    def post(endpoint, body)
      HTTParty.post("#{@self_url}#{endpoint}",
                    headers: {
                      'Content-Type' => 'application/json',
                      'Authorization' => "Bearer #{@jwt.auth_token}"
                    },
                    body: body)
    end
  end
end
