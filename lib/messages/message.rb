require_relative "identity_info_req"
require_relative "identity_info_resp"

module Selfid
  module Messages
    def self.parse(input, client, jwt_client, messaging)
      jwt = JSON.parse(jwt_client.decode(input.ciphertext), symbolize_names: true)
      payload = JSON.parse(jwt_client.decode(jwt[:payload]), symbolize_names: true)

      case payload[:typ]
      when "identity_info_req"
        m = IdentityInfoReq.new(client, jwt_client, messaging)
        m.parse(input)
        return m
      when "identity_info_resp"
        m = IdentityInfoResp.new(client, jwt_client, messaging)
        m.parse(input)
        return m
      else
        raise StandardError "Invalid message type."
      end
    end
  end
end
