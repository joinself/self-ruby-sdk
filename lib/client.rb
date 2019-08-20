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
      raise 'An error has occured' if res.code != 200
    end

    # Get identity details
    #
    # @param id [string] identity id.
    def identity(id)
      res = get "/v1/identities/#{id}"
      raise 'An error has occured' if res.code != 200

      JSON.parse(res.body, symbolize_names: true)
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
