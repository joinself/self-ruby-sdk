# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'chat'

module SelfSDK
  module Messages
    class ChatMessage < Chat
      MSG_TYPE = "chat.message"
      DEFAULT_EXP_TIMEOUT = 900

      attr_accessor :body

      def parse(input, envelope=nil)
        super
        @typ = MSG_TYPE
        @body = @payload[:msg]
      end

    end
  end
end
