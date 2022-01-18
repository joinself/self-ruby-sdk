# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'chat'

module SelfSDK
  module Messages
    class ChatMessageRead < Chat
      MSG_TYPE = "chat.message.read"
      DEFAULT_EXP_TIMEOUT = 900

      def parse(input, envelope=nil)
        super
        @typ = MSG_TYPE
      end

    end
  end
end
