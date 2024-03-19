# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'self_msgproto'
require_relative 'base'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class Generic < Base
      def parse(input, envelope=nil)
        @input = input
        @payload = get_payload input
        @id = @payload[:jti]
        @from = @payload[:iss]
        @to = @payload[:sub]
        @audience = payload[:aud]
        @expires = @payload[:exp]
        @typ = @payload[:typ]
        @body = @payload[:msg]

        if envelope
          issuer = envelope.sender.split(":")
          @from = issuer.first
          @from_device = issuer.last
        end
      end
    end
  end
end
