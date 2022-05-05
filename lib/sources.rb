# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require "json"
module SelfSDK
  class Sources
    def initialize(sources_file)
      data = JSON.parse('{
          "sources": {
              "user_specified": [
                  "document_number",
                  "display_name",
                  "email_address",
                  "phone_number"
              ],
              "passport": [
                  "document_number",
                  "surname",
                  "given_names",
                  "date_of_birth",
                  "date_of_expiration",
                  "sex",
                  "nationality",
                  "country_of_issuance"
              ],
              "driving_license": [
                  "document_number",
                  "surname",
                  "given_names",
                  "date_of_birth",
                  "date_of_issuance",
                  "date_of_expiration",
                  "address",
                  "issuing_authority",
                  "place_of_birth"
              ],
              "identity_card": [
                  "document_number",
                  "surname",
                  "given_names",
                  "date_of_birth",
                  "date_of_expiration",
                  "sex",
                  "nationality",
                  "country_of_issuance"
              ],
              "twitter": [
                  "account_id",
                  "nickname"
              ],
              "linkedin": [
                  "account_id",
                  "nickname"
              ],
              "facebook": [
                  "account_id",
                  "nickname"
              ],
              "live": [
                  "selfie_verification"
              ]
          }
      }')
      @sources = data["sources"]
      @facts = []
      @sources.each do |source, facts|
        @facts.push(*facts)
      end
    end

    def normalize_fact_name!(fact)
      fact = fact.to_s
      raise "invalid fact '#{fact}'" unless @facts.include?(fact)
      fact
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

    def message_type(s)
      types = { authentication_request: SelfSDK::Messages::AuthenticationReq::MSG_TYPE,
                authentication_response: SelfSDK::Messages::AuthenticationResp::MSG_TYPE,
                fact_request: SelfSDK::Messages::FactRequest::MSG_TYPE,
                fact_response: SelfSDK::Messages::FactResponse::MSG_TYPE,
                chat_message: SelfSDK::Messages::ChatMessage::MSG_TYPE,
                chat_message_deivered: SelfSDK::Messages::ChatMessageDelivered::MSG_TYPE,
                chat_message_read: SelfSDK::Messages::ChatMessageRead::MSG_TYPE,
                chat_invite: SelfSDK::Messages::ChatInvite::MSG_TYPE,
                chat_join: SelfSDK::Messages::ChatJoin::MSG_TYPE,
                chat_remove: SelfSDK::Messages::ChatRemove::MSG_TYPE,
                document_sign_response: SelfSDK::Messages::DocumentSignResponse::MSG_TYPE,
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
