# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

module SelfSDK
  module Chat
    class Message
      attr_accessor :gid, :body, :from, :payload, :recipients, :objects, :rid, :cid

      def initialize(chat, recipients, payload, auth_token, self_url)
        @chat = chat
        @recipients = recipients
        @recipients = [@recipients] if @recipients.is_a? String
        @gid = payload[:gid] if payload.key? :gid
        @rid = payload[:rid] if payload.key? :rid
        @cid = payload[:cid] if payload.key? :cid
        @payload = payload
        @payload[:jti] = SecureRandom.uuid unless @payload.include?(:jti)
        @body = @payload[:msg]
        @from = @payload[:iss]
        return unless @payload.key?(:objects)

        @objects = []
        @payload[:objects].each do |o|
          @objects << if o.key? :link
                        SelfSDK::Chat::FileObject.new(auth_token, self_url).build_from_object(o)
                      else
                        SelfSDK::Chat::FileObject.new(auth_token, self_url).build_from_data(o[:name], o[:data], o[:mime])
                      end
        end
        @payload[:objects] = []
        @payload[:objects] = payload[:raw_objects] if payload[:raw_objects]
        @objects.each do |o|
          @payload[:objects] << o.to_payload
        end
      end

      # delete! deletes the current message from the conversation.
      def delete!
        @chat.delete(@recipients, @payload[:jti], @payload[:gid])
      end

      # edit changes the current message body for all participants.
      #
      # @param body [string] the new message body.
      def edit(body)
        return if @recipients == [@chat.app_id]

        @body = body
        @chat.edit(@recipients, @payload[:jti], body, @payload[:gid])
      end

      # mark_as_delivered marks the current message as delivered if 
      # it comes from another recipient.
      def mark_as_delivered
        return if @recipients != [@chat.app_id]

        @chat.delivered(@payload[:iss], @payload[:jti], @payload[:gid])
      end

      # mark_as_read marks the current message as read if it comes from
      # another recipient.
      def mark_as_read
        return if @recipients != [@chat.app_id]

        @chat.read(@payload[:iss], @payload[:jti], @payload[:gid])
      end

      # respond sends a direct response to the current message.
      #
      # @param body [string] the new message body.
      #
      # @return ChatMessage
      def respond(body, opts = {})
        opts[:aud] = @payload[:gid] if @payload.key? :gid
        opts[:gid] = @payload[:gid] if @payload.key? :gid
        opts[:rid] = @payload[:jti]

        to = @recipients
        to = [@payload[:iss]] if @recipients == [@chat.app_id]

        @chat.message(to, body, opts)
      end

      # message sends a new message to the same conversation as the current message.
      #
      # @param body [string] the new message body.
      #
      # @return ChatMessage
      def message(body, opts = {})
        opts[:aud] = @payload[:gid] if @payload.key? :gid
        opts[:gid] = @payload[:gid] if @payload.key? :gid

        to = opts[:recipients] if opts.key? :recipients
        to = [@payload[:iss]] if @recipients == [@chat.app_id]

        @chat.message(to, body, opts)
      end

    end
  end
end