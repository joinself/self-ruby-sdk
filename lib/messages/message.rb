# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative "fact_request"
require_relative "fact_response"
require_relative "authentication_resp"
require_relative "authentication_req"

module SelfSDK
  module Messages
    def self.parse(input, messaging, original=nil)
      body = if input.is_a? String
               input
             else
               issuer = input.sender.split(":")
               messaging.encryption_client.decrypt(input.ciphertext, issuer.first, issuer.last)
             end

      jwt = JSON.parse(body, symbolize_names: true)
      payload = JSON.parse(messaging.jwt.decode(jwt[:payload]), symbolize_names: true)

      case payload[:typ]
      when "identities.facts.query.req"
        m = FactRequest.new(messaging)
        m.parse(body)
      when "identities.facts.query.resp"
        m = FactResponse.new(messaging)
        m.parse(body)
      when "identities.authenticate.resp"
        m = AuthenticationResp.new(messaging)
        m.parse(body)
      when "identities.authenticate.req"
        m = AuthenticationReq.new(messaging)
        m.parse(body)
      else
        raise StandardError.new("Invalid message type.")
      end
      return m
    end
  end
end
