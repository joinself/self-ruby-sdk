# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'httparty'

module SelfSDK
  class RestClient
    attr_reader :self_url, :jwt, :env

    # RestClient initializer
    #
    # @param url [string] self-messaging url
    # @param token [string] jwt token identifying the authenticated user
    def initialize(url, app_id, app_key, env)
      SelfSDK.logger.info "client setup with #{url}"
      @self_url = url
      @env = env
      @jwt = SelfSDK::JwtService.new(app_id, app_key)
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
        SelfSDK.logger.debug "getting devices response : #{body[:message]}"
        raise "you need connection permissions"
      end
      body
    end

    # Lists all public keys stored on self for the given ID
    #
    # @param id [string] identity id
    # DEPRECATED
    def public_keys(id)
      i = entity(id)
      i[:public_keys]
    end

    def post(endpoint, body)
      safe_request do
        HTTParty.post("#{@self_url}#{endpoint}",
                      headers: {
                        'Content-Type' => 'application/json',
                        'Authorization' => "Bearer #{@jwt.auth_token}"
                      },
                      body: body)
      end
    end

    def get(endpoint)
      safe_request do
        HTTParty.get("#{@self_url}#{endpoint}", 
                     headers: {
                        'Content-Type'  => 'application/json',
                        'Authorization' => "Bearer #{@jwt.auth_token}"
                      })
      end
    end

    def safe_request(&block)
      res = nil
      loop do
        begin
          res = block.call

          break if res.code == 200
          next if res.code == 503
          next if body[:error_id] == 'token_expired'

          break
        rescue StandardError
          # retry if the server is down
        end
        sleep 2
      end
      res
    end

    # Lists all public keys stored on self for the given ID
    #
    # @param id [string] identity id
    def public_key(id, kid)
      i = entity(id)
      sg = SelfSDK::SignatureGraph.new(i[:history])
      sg.key_by_id(kid)
    end

    # Get the active public key for a device
    #
    # @param id [string] identity id
    def device_public_key(id, did)
      i = entity(id)
      sg = SelfSDK::SignatureGraph.new(i[:history])
      sg.key_by_device(did)
    end

    private

    def get_identity(endpoint)
      res = get endpoint
      body = JSON.parse(res.body, symbolize_names: true)
      if res.code != 200
        SelfSDK.logger.error "app response : #{body[:message]}"
        raise body[:message]
      end
      body
    end


  end
end
