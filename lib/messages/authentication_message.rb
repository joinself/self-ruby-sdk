# frozen_string_literal: true

require_relative 'base'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class AuthenticationMessage < Base

      def parse(input, original=nil)
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
      end
    end
  end
end
