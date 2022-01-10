module SelfSDK
  module Services
    class ChatMessage
      attr_accessor :gid, :body, :from

      def initialize(chat, recipients, payload)
        @chat = chat
        @recipients = recipients
        @recipients = [@recipients] if @recipients.is_a? String
        @gid = payload[:gid] if payload.key? :gid
        @payload = payload
        @payload[:jti] = SecureRandom.uuid unless @payload.include?(:jti)
        @body = @payload[:msg]
        @from = @payload[:iss]
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
      def respond(body)
        opts = {}
        opts[:aud] = @payload[:gid] if @payload.key? :gid
        opts[:gid] = @payload[:gid] if @payload.key? :gid
        opts[:rid] = @payload[:jti]

        to = @recipients
        to = [@payload[:iss]] if @recipients = [@chat.app_id]

        @chat.message(to, body, opts)
      end

      # message sends a new message to the same conversation as the current message.
      #
      # @param body [string] the new message body.
      #
      # @return ChatMessage
      def message(body, recs = nil)
        opts = {}
        opts[:aud] = @payload[:gid] if @payload.key? :gid
        opts[:gid] = @payload[:gid] if @payload.key? :gid

        to = recs || @recipients
        to = [@payload[:iss]] if @recipients = [@chat.app_id]

        @chat.message(to, body, opts)
      end
    end

    class ChatGroup
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

        _req = send(recipients, payload)
        ChatMessage.new(self, recipients, payload)
      end


      def on_message(opts = {}, &block)
        @messaging.subscribe :chat_message do |msg|
          puts "(#{msg.payload[:iss]}, #{msg.payload[:jti]})"
          cm = ChatMessage.new(self, msg.payload[:aud], msg.payload)

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

      def edit(recipients, cid, body, gid = nil)
        send(recipients, {
          typ: "chat.message.edit",
          cid: cid,
          msg: body,
          gid: gid,
        })
      end

      # Sends a message to delete a specific message.
      #
      # @param recipient [string] the recipient of the message
      # @param cid [string] message cid to be marked as read.
      # @param gid [string] group id where the conversation ids are referenced.
      def delete(recipients, cids, gid = nil)
        cids = [cids] if cids.is_a? String
        send(recipients, {
          typ: "chat.message.delete",
          cids: cids,
          gid: gid,
        })
      end

      def on_invite(&block)
        @messaging.subscribe :chat_invite do |msg|
          g = ChatGroup.new(self, msg.payload)
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
        @messaging.send(members, typ: "chat.invite",
                                 gid: gid,
                                 name: name,
                                 members: members)

          #TODO: support objects.
=begin
          if opts.key? :obj
            b.merge!({
              link: "",
              mime: "",
              expires: "",
              key: "",
            })
          end
=end
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
