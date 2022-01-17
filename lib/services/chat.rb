# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'self_crypto'
require_relative '../chat/file_object'
require_relative '../chat/group'
require_relative '../chat/message'
module SelfSDK
  module Services
    class Chat
      attr_accessor :app_id

      def initialize(messaging, client)
        @messaging = messaging
        @client = client
        @app_id = @client.jwt.id
      end

      # Sends a message to a list of recipients.
      #
      # @param recipients [array]  list of recipients to send the message to.
      # @param body [string] the message content to be sent
      def message(recipients, body, opts = {})
        payload = {
          typ: "chat.message",
          msg: body,
        }
        payload[:aud] = opts[:gid] if opts.key? :gid
        payload[:gid] = opts[:gid] if opts.key? :gid
        payload[:rid] = opts[:rid] if opts.key? :rid
        payload[:objects] = opts[:objects] if opts.key? :objects

        m = SelfSDK::Chat::Message.new(self, recipients, payload, @messaging.client.jwt.auth_token, @client.self_url)
        _req = send(m.recipients, m.payload)

        m
      end

      # Subscribes to an incoming chat message
      def on_message(opts = {}, &block)
        @messaging.subscribe :chat_message do |msg|
          puts "(#{msg.payload[:iss]}, #{msg.payload[:jti]})"
          cm = SelfSDK::Chat::Message.new(self, msg.payload[:aud], msg.payload, @messaging.client.jwt.auth_token, @client.self_url)

          cm.mark_as_delivered unless opts[:mark_as_delivered] == false
          cm.mark_as_read if opts[:mark_as_read] == true

          block.call(cm)
        end
      end

      # Sends a message to confirm a list of messages (identified by it's cids)
      # have been delivered.
      #
      # @param recipients [array]  list of recipients to send the message to.
      # @param cids [array] list of message cids to be marked as delivered.
      # @param gid [string] group id where the conversation ids are referenced.
      def delivered(recipients, cids, gid = nil)
        confirm('delivered', recipients, cids, gid)
      end

      # Sends a message to confirm a list of messages (identified by it's cids)
      # have been read.
      #
      # @param recipients [array]  list of recipients to send the message to.
      # @param cids [array] list of message cids to be marked as read.
      # @param gid [string] group id where the conversation ids are referenced.
      def read(recipients, cids, gid = nil)
        confirm('read', recipients, cids, gid)
      end

      # Modifies a previously sent message
      #
      # @param recipients [array]  list of recipients to send the message to.
      # @param cids [array] list of message cids to be marked as read.
      # @param body [string] the new body to replace the previous one.
      # @param gid [string] group id where the conversation ids are referenced.
      def edit(recipients, cid, body, gid = nil)
        send(recipients, { typ: "chat.message.edit",
                           cid: cid,
                           msg: body,
                           gid: gid })
      end

      # Sends a message to delete a specific message.
      #
      # @param recipient [string] the recipient of the message
      # @param cid [string] message cid to be marked as read.
      # @param gid [string] group id where the conversation ids are referenced.
      def delete(recipients, cids, gid = nil)
        cids = [cids] if cids.is_a? String
        send(recipients, { typ: "chat.message.delete",
                           cids: cids,
                           gid: gid })
      end

      def on_invite(&block)
        @messaging.subscribe :chat_invite do |msg|
          g = SelfSDK::Chat::Group.new(self, msg.payload)
          block.call(g)
        end
      end

      def on_join(&block)
        @messaging.subscribe :chat_join do |msg|
          block.call(iss: msg.payload[:iss], gid: msg.payload[:gid])
        end
      end

      def on_leave(&block)
        @messaging.subscribe :chat_remove do |msg|
          block.call(iss: msg.payload[:iss], gid: msg.payload[:gid])
        end
      end

      # Invite sends group invitation to a list of members.
      #
      # @param gid [string] group id.
      # @param name [string] name of the group.
      # @param members [array] list of group members.
      def invite(gid, name, members, opts = {})
        payload = { typ: "chat.invite",
                    gid: gid,
                    name: name,
                    members: members }

        if opts.key? :data
          obj = SelfSDK::Chat::FileObject.new(@messaging.client.jwt.auth_token, @client.self_url)
          obj_payload = obj.build_from_data("", opts[:data], opts[:mime]).to_payload
          obj_payload.delete(:name)
          payload.merge! obj_payload
        end

        @messaging.send(members, payload)
        SelfSDK::Chat::Group.new(self, payload)
      end

      # Join a group
      #
      # @param gid [string] group id.
      # @param members [array] list of group members.
      def join(gid, members)
        send(members, typ: 'chat.join', gid: gid, aud: gid)
      end

      # Leaves a group
      #
      # @param gid [string] group id.
      # @members members [array] list of group members.
      def leave(gid, members)
        send(members, typ: "chat.remove", gid: gid )
      end

      private

      # sends a confirmation for a list of messages to a list of recipients.
      def confirm(action, recipients, cids, gid = nil)
        cids = [cids] if cids.is_a? String
        gid = recipients if gid.nil? || gid.empty?
        p " -> chat.message.#{action} (#{recipients} - #{cids})"
        send(recipients, {
          typ: "chat.message.#{action}",
          cids: cids,
          gid: gid
        })
      end

      # sends a message to a list of recipients.
      def send(recipients, body)
        recipients = [recipients] if recipients.is_a? String
        m = []
        recipients.each do |r|
          m << @messaging.send(r, body)
        end
        m
      end
    end
  end
end
