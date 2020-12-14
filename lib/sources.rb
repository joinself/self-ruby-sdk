# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

module SelfSDK
  FACT_EMAIL = "email_address"
  FACT_PHONE = "phone_number"
  FACT_DISPLAY_NAME = "display_name"
  FACT_DOCUMENT_NUMBER = "document_number"
  FACT_GIVEN_NAMES = "given_names"
  FACT_SURNAME = "surname"
  FACT_SEX = "sex"
  FACT_ISSUING_AUTHORITY = "issuing_authority"
  FACT_NATIONALITY = "nationality"
  FACT_ADDRESS = "address"
  FACT_PLACE_OF_BIRTH = "place_of_birth"
  FACT_DATE_OF_BIRTH = "date_of_birth"
  FACT_DATE_OF_ISSUANCE = "date_of_issuance"
  FACT_DATE_OF_EXPIRATION = "date_of_expiration"
  FACT_VALID_FROM = "valid_from"
  FACT_VALID_TO = "valid_to"
  FACT_CATEGORIES = "categories"
  FACT_SORT_CODE = "sort_code"
  FACT_COUNTRY_OF_ISSUANCE = "country_of_issuance"

  SOURCE_USER_SPECIFIED = "user_specified"
  SOURCE_PASSPORT = "passport"
  SOURCE_DRIVING_LICENSE = "driving_license"
  SOURCE_IDENTITY_CARD = "identity_card"

  class << self
    def message_type(s)
      types = { authentication_request: SelfSDK::Messages::AuthenticationReq::MSG_TYPE,
                authentication_response: SelfSDK::Messages::AuthenticationResp::MSG_TYPE,
                fact_request: SelfSDK::Messages::FactRequest::MSG_TYPE,
                fact_response: SelfSDK::Messages::FactResponse::MSG_TYPE }
      raise "invalid message type" unless types.key? s
      return types[s]
    end

    def operator(input)
      operators = { equals: '==',
                    different: '!=',
                    great_or_equal_than: '>=',
                    less_or_equal: '<=',
                    great_than: '>',
                    less_than: '<' }
      get(operators, input, "operator")
    end

    def fact_name(input)
      facts = { email_address: FACT_EMAIL,
                phone_number: FACT_PHONE,
                display_name: FACT_DISPLAY_NAME,
                document_number: FACT_DOCUMENT_NUMBER,
                given_names: FACT_GIVEN_NAMES,
                surname: FACT_SURNAME,
                sex: FACT_SEX,
                issuing_authority: FACT_ISSUING_AUTHORITY,
                nationality: FACT_NATIONALITY,
                address: FACT_ADDRESS,
                place_of_birth: FACT_PLACE_OF_BIRTH,
                date_of_birth: FACT_DATE_OF_BIRTH,
                date_of_issuance: FACT_DATE_OF_ISSUANCE,
                date_of_expiration: FACT_DATE_OF_EXPIRATION,
                valid_from: FACT_VALID_FROM,
                valid_to: FACT_VALID_TO,
                categories: FACT_CATEGORIES,
                sort_code: FACT_SORT_CODE,
                country_of_issuance: FACT_COUNTRY_OF_ISSUANCE }
      get(facts, input, "fact")
    end

    def source(input)
      sources = { user_specified: SOURCE_USER_SPECIFIED,
                passport: SOURCE_PASSPORT,
                driving_license: SOURCE_DRIVING_LICENSE,
                identity_card: SOURCE_IDENTITY_CARD }
      get(sources, input, "source")
    end

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
