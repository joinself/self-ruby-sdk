# frozen_string_literal: true

require_relative 'base'
require_relative '../ntptime'

module Selfid
  module Messages
    class AuthenticationMessage < Base

      def parse(input)
        @input = input
        @typ = @typ
        @payload = get_payload input
        @id = payload[:cid]
        @from = payload[:iss]
        @to = payload[:sub]
        @from_device = payload[:device_id]
        @expires = payload[:exp]
        @status = payload[:status]
      end
    end
  end
end
