# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true
require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfsdk'

require 'webmock/minitest'

class Chat < Minitest::Test
  describe 'chat' do
    let(:jti) { "jti" }
    let(:app_id) { "app_id" }
    let(:messaging_client) { double("messaging_client", jwt: jwt, self_url: "https://api.joinself.com") }
    let(:m_client) { double("m_client", client: messaging_client) }
    let(:messaging) { double("messaging", client: m_client) }
    let(:jwt) { double("jwt", id: app_id, auth_token: "TOK_123") }
    let(:client) { double("client" ) }
    let(:chat) do
      SelfSDK::Services::Chat.new(messaging, client)
    end

    describe "initialization" do
      let(:payload) { { iss: "iss" } }
      def test_initialisation
        assert_equal app_id, chat.app_id
      end
    end

    describe "message" do
      let(:result) { "res" }
      let(:recipients) { ["a", "b"] }
      let(:body) { "hello" }
      it "should send a message" do
        recipients.each do |recipient|
          expect(messaging).to receive(:send).with(recipient, {typ: "chat.message", jti: jti, msg: body}).and_return(result)
        end
        m = chat.message(recipients, body, jti: jti )
        assert_equal recipients, m.recipients
      end
    end

    describe "delivered" do
      let(:result) { "res" }
      let(:recipients) { ["a", "b"] }
      let(:cids) { ["cid"] }
      it "should send a message" do
        recipients.each do |recipient|
          expect(messaging).to receive(:send).with(recipient, typ: "chat.message.delivered", cids: cids, gid: recipients).and_return(result)
        end
        res = chat.delivered(recipients, cids)
        assert_equal ["res", "res"], res
      end
    end

    describe "read" do
      let(:result) { "res" }
      let(:recipients) { ["a", "b"] }
      let(:cids) { ["cid"] }
      it "should send a message" do
        recipients.each do |recipient|
          expect(messaging).to receive(:send).with(recipient, typ: "chat.message.read", cids: cids, gid: recipients).and_return(result)
        end
        res = chat.read(recipients, cids)
        assert_equal ["res", "res"], res
      end
    end

    describe "edit" do
      let(:result) { "res" }
      let(:recipients) { ["a", "b"] }
      let(:body) { "edited" }
      let(:cid) { "cid" }
      it "should send a message" do
        recipients.each do |recipient|
          expect(messaging).to receive(:send).with(recipient, typ: "chat.message.edit",
                                                              cid: cid,
                                                              msg: body,
                                                              gid: nil).and_return(result)
        end
        res = chat.edit(recipients, cid, body)
        assert_equal ["res", "res"], res
      end
    end

    describe "delete" do
      let(:result) { "res" }
      let(:recipients) { ["a", "b"] }
      let(:cids) { ["cid"] }
      it "should send a message" do
        recipients.each do |recipient|
          expect(messaging).to receive(:send).with(recipient, typ: "chat.message.delete",
                                                              cids: cids,
                                                              gid: nil).and_return(result)
        end
        res = chat.delete(recipients, cids)
        assert_equal ["res", "res"], res
      end
    end

    describe "invite" do
      let(:result) { "res" }
      let(:members) { ["a", "b"] }
      let(:group_name) { "group_name" }
      let(:gid) { "gid" }
      it "should send a message" do
        expect(messaging).to receive(:send).with(members, typ: "chat.invite",
                                                            gid: gid,
                                                            name: group_name,
                                                            members: members).and_return(result)
        res = chat.invite(gid, group_name, members)
        assert_equal group_name, res.name
      end
    end

  end
end
