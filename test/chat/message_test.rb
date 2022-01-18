# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true
require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfsdk'

require 'webmock/minitest'

class Message < Minitest::Test
  describe 'message' do
    let(:chat) { double("chat",) }
    let(:recipients) { ["A", "B", "C"] }
    let(:payload) { { iss: "iss", jti: "jti", gid: "gid" } }
    let(:auth_token) { "TOKabc" }
    let(:result) { "r" }
    let(:self_url) { "https://api.joinself.com" }

    let(:msg) do
      SelfSDK::Chat::Message.new(chat, recipients, payload, auth_token, self_url)
    end

    describe "initialization" do
      let(:payload) { { iss: "iss" } }
      def test_initialisation
        assert_nil msg.gid
        assert_nil msg.body
        assert_nil msg.objects
        assert_equal payload[:iss], msg.from
        assert_equal payload, msg.payload
        assert_equal recipients, msg.recipients
      end
    end

    describe "delete!" do
      def test_delete!
        expect(chat).to receive(:delete).with(recipients, payload[:jti], payload[:gid]).and_return(result)
        assert_equal result, msg.delete!
      end
    end

    describe "edit" do
      let(:edited_body) { "new body" }
      def test_edit
        expect(chat).to receive(:app_id).and_return("app_id")
        expect(chat).to receive(:edit).with(recipients, payload[:jti], edited_body, payload[:gid]).and_return(result)
        assert_equal result, msg.edit(edited_body)
      end
    end

    describe "mark_as_delivered" do
      let(:recipients) { ["app_id"] }
      def test_mark_as_delivered
        expect(chat).to receive(:app_id).and_return("app_id")
        expect(chat).to receive(:delivered).with(payload[:iss], payload[:jti], payload[:gid]).and_return(result)
        assert_equal result, msg.mark_as_delivered
      end
    end

    describe "mark_as_read" do
      let(:recipients) { ["app_id"] }
      def test_mark_as_read
        expect(chat).to receive(:app_id).and_return("app_id")
        expect(chat).to receive(:read).with(payload[:iss], payload[:jti], payload[:gid]).and_return(result)
        assert_equal result, msg.mark_as_read
      end
    end

    describe "respond my message message" do
      let(:body) { "body" }

      def test_respond
        expect(chat).to receive(:app_id).and_return("app_id")
        opts = { aud: payload[:gid], gid: payload[:gid], rid: payload[:jti] }
        expect(chat).to receive(:message).with(recipients, body, opts).and_return(result)

        assert_equal result, msg.respond(body)
      end
    end
  end
end
