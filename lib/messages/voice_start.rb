# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'chat'

module SelfSDK
  module Messages
    class VoiceStart < Chat
      MSG_TYPE = "chat.voice.start"

      def parse(input, envelope=nil)
        super
        @typ = MSG_TYPE
      end

    end
  end
end
