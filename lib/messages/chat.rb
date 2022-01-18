# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'self_msgproto'
require_relative 'base'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class Chat < Base
      def parse(input, envelope=nil)
        @input = input
        @payload = get_payload input
        @id = @payload[:jti]
        @from = @payload[:iss]
        @to = @payload[:sub]
        @audience = payload[:aud]
        @expires = @payload[:exp]

        if envelope
          issuer = envelope.sender.split(":")
          @from_device = issuer.last
        end
      end
    end
  end
end
