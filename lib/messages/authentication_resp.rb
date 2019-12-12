# frozen_string_literal: true

require_relative 'base'
require_relative '../ntptime'

module Selfid
  module Messages
    class AuthenticationResp < Base
      MSG_TYPE = "authentication_resp"

      def parse(input)
        @input = input
        @typ = MSG_TYPE
        @payload = get_payload input
        @id = payload[:cid]
        @from = payload[:iss]
        @to = payload[:sub]
        @from_device = payload[:device_id]
        @expires = payload[:exp]
        @status = payload[:status]
      end

      protected

      def proto
        nil
      end
    end
  end
end
