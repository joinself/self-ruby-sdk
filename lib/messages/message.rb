# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative "fact_request"
require_relative "fact_response"
require_relative "authentication_resp"
require_relative "authentication_req"
require_relative "chat_message"
require_relative "chat_message_read"
require_relative "chat_message_delivered"
require_relative "chat_invite"
require_relative "chat_join"
require_relative "chat_remove"
require_relative "document_sign_resp"

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
      when SelfSDK::Messages::ChatMessage::MSG_TYPE
        m = ChatMessage.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::ChatMessageDelivered::MSG_TYPE
        m = ChatMessageDelivered.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::ChatMessageRead::MSG_TYPE
        m = ChatMessageRead.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::ChatInvite::MSG_TYPE
        m = ChatInvite.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::ChatRemove::MSG_TYPE
        m = ChatRemove.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::ChatJoin::MSG_TYPE
        m = ChatJoin.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::DocumentSignResponse::MSG_TYPE
        m = DocumentSignResponse.new(messaging)
        m.parse(body, envelope)
      else
        raise StandardError.new("Invalid message type #{payload[:typ]}.")
      end
      return m
    end
  end
end
