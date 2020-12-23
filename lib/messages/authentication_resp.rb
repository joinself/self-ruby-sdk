# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'base'
require_relative '../ntptime'
require_relative 'authentication_message'

module SelfSDK
  module Messages
    class AuthenticationResp < AuthenticationMessage
      MSG_TYPE = "identities.authenticate.resp"
      def initialize(messaging)
        @typ = MSG_TYPE
        super
      end

      protected

      def proto(to_device)
        nil
      end
    end
  end
end
