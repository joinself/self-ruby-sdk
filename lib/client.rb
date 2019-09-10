# frozen_string_literal: true

require 'httparty'

module Selfid
  class RestClient
    attr_reader :self_url

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

    # Get identity details
    #
    # @param id [string] identity id.
    def identity(id)
      res = get "/v1/identities/#{id}"
      body = JSON.parse(res.body, symbolize_names: true)
      if res.code != 200
        Selfid.logger.error "identity response : #{body[:message]}"
        raise body[:message]
      end
      body
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
                    body: body,)
    end
  end
end
