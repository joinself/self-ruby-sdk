# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'self_crypto'
require_relative '../chat/file_object'
require_relative '../chat/group'
require_relative '../chat/message'
require_relative "../messages/connection_request"

module SelfSDK
  module Services
    class Voice
      attr_accessor :app_id

      def initialize(messaging)
        @messaging = messaging
      end

      # Sends a chat.voice.setup message to setup a delegated call.
      def setup(recipient, name, cid)
        payload = { typ: SelfSDK::Messages::VoiceSetup::MSG_TYPE }
        payload[:cid] = cid
        payload[:data] = { name: name }

        send([recipient], payload)
      end

      # Subscribes to chat.voice.setup messages.
      def on_setup(&block)
        @messaging.subscribe :voice_setup do |msg|
          block.call(msg.payload[:iss], msg.payload[:cid], msg.payload[:data])
        end
      end

      # Sends a chat.voice.start message with the details for starting a call.
      def start(recipient, cid, call_id, peer_info, data)
        send([recipient],
             typ: SelfSDK::Messages::VoiceStart::MSG_TYPE,
             cid: cid,
             call_id: call_id,
             peer_info: peer_info,
             data: data)
      end

      # Subscribes to chat.voice.start messages.
      def on_start(&block)
        @messaging.subscribe :voice_start do |msg|
          block.call(msg.payload[:iss],
                     cid: msg.payload[:cid],
                     call_id: msg.payload[:call_id],
                     peer_info: msg.payload[:peer_info],
                     data: msg.payload[:data])
        end
      end

      # Sends a chat.voice.accept message accepting a specific call.
      def accept(recipient, cid, call_id, peer_info)
        payload = { 
          typ: SelfSDK::Messages::VoiceAccept::MSG_TYPE,
          cid: cid,
          call_id: call_id,
          peer_info: peer_info,
        }
        send([recipient], payload)
      end

      # Subscribes to chat.voice.accept messages.
      def on_accept(&block)
        @messaging.subscribe :voice_accept do |msg|
          block.call(msg.payload[:iss], 
                     cid: msg.payload[:cid],
                     call_id: msg.payload[:call_id],
                     peer_info: msg.payload[:peer_info])
        end
      end

      # Sends a chat.voice.accept message finishing the call.
      def stop(recipient, cid, call_id)
        payload = { 
          typ: SelfSDK::Messages::VoiceStop::MSG_TYPE,
          cid: cid,
          call_id: call_id,
        }
        send([recipient], payload)
      end

      # Subscribes to chat.voice.stop messages.
      def on_stop(&block)
        @messaging.subscribe :voice_stop do |msg|
          block.call(msg.payload[:iss], 
                     cid: msg.payload[:cid],
                     call_id: msg.payload[:call_id],
                     peer_info: msg.payload[:peer_info])
        end
      end

      # Sends a chat.voice.busy message finishing the call.
      def busy(recipient, cid, call_id)
        send([recipient],
             typ: SelfSDK::Messages::VoiceBusy::MSG_TYPE,
             cid: cid,
             call_id: call_id)
      end

      # Subscribes to chat.voice.busy messages.
      def on_busy(&block)
        @messaging.subscribe :voice_busy do |msg|
          block.call(msg.payload[:iss], 
                     cid: msg.payload[:cid],
                     call_id: msg.payload[:call_id],
                     peer_info: msg.payload[:peer_info])
        end
      end

      # Sends a chat.voice.summary message Sending details about the call.
      def summary(recipient, cid, call_id)
        send([recipient],
             typ: SelfSDK::Messages::VoiceSummary::MSG_TYPE,
             cid: cid,
             call_id: call_id)
      end

      # Subscribes to chat.voice.summary messages.
      def on_summary(&block)
        @messaging.subscribe :voice_summary do |msg|
          block.call(msg.payload[:iss], 
                     cid: msg.payload[:cid],
                     call_id: msg.payload[:call_id],
                     peer_info: msg.payload[:peer_info])
        end
      end

      private

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
