# frozen_string_literal: true

require 'httparty'

module Selfid
  class RestClient
    attr_reader :self_url, :jwt, :env

    # RestClient initializer
    #
    # @param url [string] self-messaging url
    # @param token [string] jwt token identifying the authenticated user
    def initialize(url, app_id, app_key, env)
      Selfid.logger.info "client setup with #{url}"
      @self_url = url
      @env = env
      @jwt = Selfid::JwtService.new(app_id, app_key)
    end

    # Get identity details
    #
    # @param id [string] identity self_id.
    def identity(id)
      get_identity "/v1/identities/#{id}"
    end

    # Get app details
    #
    # @param id [string] app self_id.
    def app(id)
      get_identity "/v1/apps/#{id}"
    end

    # Get app/identity details
    #
    # @param id [string] app/identity self_id.
    def entity(id)
      #TODO : Consider a better check for this conditional
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
      i = entity(id)
      i[:public_keys]
    end

    def post(endpoint, body)
      HTTParty.post("#{@self_url}#{endpoint}",
                    headers: {
                        'Content-Type' => 'application/json',
                        'Authorization' => "Bearer #{@jwt.auth_token}"
                    },
                    body: body)
    end

    def get(endpoint)
      HTTParty.get("#{@self_url}#{endpoint}", headers: {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@jwt.auth_token}"
      })
    end

    private

    def get_identity(endpoint)
      res = get endpoint
      body = JSON.parse(res.body, symbolize_names: true)
      if res.code != 200
        Selfid.logger.error "app response : #{body[:message]}"
        raise body[:message]
      end
      body
    end


  end
end
