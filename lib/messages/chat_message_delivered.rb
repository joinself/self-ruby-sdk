# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'self_msgproto'
require_relative 'chat'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class ChatMessageDelivered < Chat
      MSG_TYPE = "chat.message.delivered"
      DEFAULT_EXP_TIMEOUT = 900

      def parse(input, envelope=nil)
        super
        @typ = MSG_TYPE
      end
    end
  end
end
