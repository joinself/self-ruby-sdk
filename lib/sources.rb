# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require "json"
require_relative "source_definition.rb"

module SelfSDK
  class Sources
    attr_reader :sources, :facts

    def initialize(sources_file)
      @sources = SOURCE_DATA["sources"]
      @facts = []
      @sources.each do |source, facts|
        @facts.push(*facts)
      end
    end

    def normalize_fact_name(fact)
      fact.to_s
    end

    def normalize_source(source)
      source.to_s
    end

    def validate_source!(source)
      raise "invalid source '#{source}'" unless @sources.keys.include?(source.to_s)
    end

    def normalize_operator!(input)
      return "" unless input

      operators = { equals: '==',
                    different: '!=',
                    great_or_equal_than: '>=',
                    less_or_equal: '<=',
                    great_than: '>',
                    less_than: '<' }
      get(operators, input, "operator")
    end

    def core_fact?(fact)
      @facts.include? fact.to_s
    end

    def message_type(s)
      types = { fact_request: SelfSDK::Messages::FactRequest::MSG_TYPE,
                fact_response: SelfSDK::Messages::FactResponse::MSG_TYPE,
                chat_message: SelfSDK::Messages::ChatMessage::MSG_TYPE,
                chat_message_deivered: SelfSDK::Messages::ChatMessageDelivered::MSG_TYPE,
                chat_message_read: SelfSDK::Messages::ChatMessageRead::MSG_TYPE,
                chat_invite: SelfSDK::Messages::ChatInvite::MSG_TYPE,
                chat_join: SelfSDK::Messages::ChatJoin::MSG_TYPE,
                chat_remove: SelfSDK::Messages::ChatRemove::MSG_TYPE,
                document_sign_response: SelfSDK::Messages::DocumentSignResponse::MSG_TYPE,
                connection_response: SelfSDK::Messages::ConnectionResponse::MSG_TYPE,
                voice_setup: SelfSDK::Messages::VoiceSetup::MSG_TYPE,
                voice_start: SelfSDK::Messages::VoiceStart::MSG_TYPE,
                voice_accept: SelfSDK::Messages::VoiceAccept::MSG_TYPE,
                voice_busy: SelfSDK::Messages::VoiceBusy::MSG_TYPE,
                voice_stop: SelfSDK::Messages::VoiceStop::MSG_TYPE,
                voice_summary: SelfSDK::Messages::VoiceSummary::MSG_TYPE,
               }
      raise "invalid message type '#{s}'" unless types.key? s
      return types[s]
    end


    private

    def get(options, input, option_type)
      if input.is_a? Symbol
        raise "invalid #{option_type} '#{input.to_s}'" unless options.key? input
        return options[input]
      end
      raise "invalid #{option_type} '#{input}'" unless options.values.include? input
      input
    end
  end
end
