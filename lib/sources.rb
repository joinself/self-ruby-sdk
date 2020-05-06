# frozen_string_literal: true

module Selfid
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

  SOURCE_USER_SPECIFIED = "user_specified"
  SOURCE_PASSPORT = "passport"
  SOURCE_DRIVING_LICENSE = "driving_license"

  class << self
    def message_type(s)
      types = { authentication_request: Selfid::Messages::AuthenticationReq::MSG_TYPE,
                authentication_response: Selfid::Messages::AuthenticationResp::MSG_TYPE,
                fact_request: Selfid::Messages::FactRequest::MSG_TYPE,
                fact_response: Selfid::Messages::FactResponse::MSG_TYPE }
      raise "invalid message type" unless types.key? s
      return types[s]
    end

    def operator(s)
      operators = { equals: '==',
                    different: '!=',
                    great_or_equal_than: '>=',
                    less_or_equal: '<=',
                    great_than: '>',
                    less_than: '<' }
      raise "invalid operator" unless operators.key? s
      return operators[s]
    end

    def fact_name(s)
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
                date_of_expiration: FACT_DATE_OF_EXPIRATION }
      if s.is_a? Symbol
        raise "invalid fact name '#{s.to_s}'" unless facts.key? s
        return facts[s]
      end
      raise "invalid fact name '#{s}'" unless facts.values.include? s
      s
    end
  end
end
