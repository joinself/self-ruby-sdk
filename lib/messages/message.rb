# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative "fact_request"
require_relative "fact_response"
require_relative "authentication_resp"
require_relative "authentication_req"

module SelfSDK
  module Messages
    def self.parse(input, messaging, original=nil)
      envelope = nil
      body = if input.is_a? String
                input
             else
                envelope = input
                issuer = input.sender.split(":")
                messaging.encryption_client.decrypt(input.ciphertext, issuer.first, issuer.last)
             end

      jwt = JSON.parse(body, symbolize_names: true)
      payload = JSON.parse(messaging.jwt.decode(jwt[:payload]), symbolize_names: true)

      case payload[:typ]
      when "identities.facts.query.req"
        m = FactRequest.new(messaging)
        m.parse(body, envelope)
      when "identities.facts.query.resp"
        m = FactResponse.new(messaging)
        m.parse(body, envelope)
      when "identities.authenticate.resp"
        m = AuthenticationResp.new(messaging)
        m.parse(body, envelope)
      when "identities.authenticate.req"
        m = AuthenticationReq.new(messaging)
        m.parse(body, envelope)
      else
        raise StandardError.new("Invalid message type.")
      end
      return m
    end
  end
end
