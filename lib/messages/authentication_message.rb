# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'base'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class AuthenticationMessage < Base

      def parse(input, envelope=nil)
        @input = input
        @typ = @typ
        @payload = get_payload input
        @id = payload[:cid]
        @from = payload[:iss]
        @to = payload[:sub]
        @audience = payload[:aud]
        @from_device = payload[:device_id]
        @expires = ::Time.parse(payload[:exp])
        @issued = ::Time.parse(payload[:iat])
        @status = payload[:status]
        if envelope
          issuer = envelope.sender.split(":")
          @from_device = issuer.last
        end
      end
    end
  end
end
