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
        @link = payload[:link] if payload.key? :link
        @key = payload[:key] if payload.key? :key
        @mime = payload[:mime] if payload.key? :mime
      end

      # Sends an invitation to the specified user to join
      # the group.
      #
      # @param user [String] user to be invited.
      def invite(user)
        raise "invalid input" if user.empty?

        @members << user
        @chat.invite(@gid, @name, @members)
      end

      # Sends a message to leave the current group.
      def leave
        @chat.leave(@gid, @members)
      end

      # Sends a confi¡rmation message that has joined the group.
      def join
        @chat.join(@gid, @members)
      end

      # Sends a message to the current group
      #
      # @param body [String] message body to be sent.
      def message(body, opts = {})
        opts[:gid] = @gid
        @chat.message(@members, body, opts)
      end
    end
  end
end