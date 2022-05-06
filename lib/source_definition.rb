module SelfSDK
  SOURCE_DATA = '{
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
}'
end
