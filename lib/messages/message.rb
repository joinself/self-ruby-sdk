# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative "fact_request"
require_relative "fact_response"
require_relative "chat_message"
require_relative "chat_message_read"
require_relative "chat_message_delivered"
require_relative "chat_invite"
require_relative "chat_join"
require_relative "chat_remove"
require_relative "voice_setup"
require_relative "voice_start"
require_relative "voice_accept"
require_relative "voice_stop"
require_relative "voice_busy"
require_relative "voice_summary"
require_relative "document_sign_resp"
require_relative "connection_response"
require_relative "unknown"

module SelfSDK
  module Messages
    class UnmappedMessage < StandardError
    end
    
    def self.parse(input, messaging, original=nil)
      envelope = nil
      body = if input.is_a? String
                input
             else
                envelope = input
                issuer = input.sender.split(":")
                messaging.encryption_client.decrypt(input.ciphertext, issuer.first, issuer.last, input.offset)
             end

      jwt = JSON.parse(body, symbolize_names: true)
      payload = JSON.parse(messaging.jwt.decode(jwt[:payload]), symbolize_names: true)

      case payload[:typ]
      when SelfSDK::Messages::FactRequest::MSG_TYPE
        m = FactRequest.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::FactResponse::MSG_TYPE
        m = FactResponse.new(messaging)
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
      when SelfSDK::Messages::ConnectionResponse::MSG_TYPE
        m = ConnectionResponse.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::VoiceSetup::MSG_TYPE
        m = VoiceSetup.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::VoiceStart::MSG_TYPE
        m = VoiceStart.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::VoiceAccept::MSG_TYPE
        m = VoiceAccept.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::VoiceBusy::MSG_TYPE
        m = VoiceBusy.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::VoiceStop::MSG_TYPE
        m = VoiceStop.new(messaging)
        m.parse(body, envelope)
      when SelfSDK::Messages::VoiceSummary::MSG_TYPE
        m = VoiceSummary.new(messaging)
        m.parse(body, envelope)
      else
        m = Unknown.new(messaging)
        m.parse(body, envelope)
      end
      return m
    end
  end
end
