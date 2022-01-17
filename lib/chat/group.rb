# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

module SelfSDK
  module Chat
    class Group
      attr_accessor :gid, :name, :members, :payload

      def initialize(chat, payload)
        @chat = chat
        @payload = payload
        @gid = payload[:gid]
        @members = payload[:members]
        @name = payload[:name]
        # TODO manage object (name, link, key and mime)
      end

      def invite(user)
        @members << user
        @chat.invite(@gid, @name, @members)
      end

      def leave
        @chat.leave(@gid, @members)
      end

      def join
        @chat.join(@gid, @members)
      end

      def message(body, opts = {})
        opts[:gid] = @gid
        @chat.message(@members, body, opts)
      end
    end
  end
end