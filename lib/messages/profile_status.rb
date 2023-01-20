# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'chat'

module SelfSDK
  module Messages
    class ProfileStatus < Chat
      MSG_TYPE = "profile.status"

      def parse(input, envelope=nil)
        super
        @typ = MSG_TYPE
      end
    end
  end
end
