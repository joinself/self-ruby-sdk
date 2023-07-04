# Copyright 2020 Self Group Ltd. All Rights Reserved.

require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfsdk'

require 'webmock/minitest'

class SelfSDKTest < Minitest::Test
  describe 'parse string' do
    let(:exp) { (Time.now + 3600 * 24).to_s }
    let(:iat) { (Time.now - 3600 * 24).to_s }
    let(:jwt) { double("jwt") }
    let(:messaging) do
      double("messaging", jwt: jwt)
    end

    describe "invalid message type" do
      let(:input) { '{"payload":"test_invalid"}' }
      let(:typ) { "invalid" }
      def test_parse_invalid_message
        expect(jwt).to receive(:decode).with("test_invalid").and_return('{"typ":"invalid"}').once
        _{ SelfSDK::Messages.parse(input, messaging) }.must_raise StandardError
      end
    end

    describe "identities.facts.query.req" do
      let(:input) { '{"protected": "header", "payload":"identities.facts.query.req"}' }
      let(:typ) { "identities.facts.query.req" }
      let(:client) { double("client") }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("header").and_return('{"kid":"kid"}').once
        expect(jwt).to receive(:decode).with("identities.facts.query.req").and_return('{"typ":"identities.facts.query.req"}').twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_key).and_return(double(raw_public_key: "pk1"))
        res = SelfSDK::Messages.parse(input, messaging)
        assert_equal res.class, SelfSDK::Messages::FactRequest
      end
    end

    describe "identities.facts.query.resp" do
      let(:input) { '{"protected": "header", "payload":"identities.facts.query.resp"}' }
      let(:typ) { "identities.facts.query.resp" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"identities.facts.query.resp","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("header").and_return('{"kid":"kid"}').once
        expect(jwt).to receive(:decode).with("identities.facts.query.resp").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_key).and_return(double(raw_public_key: "pk1"))
        res = SelfSDK::Messages.parse(input, messaging)
        assert_equal res.class, SelfSDK::Messages::FactResponse
      end
    end

    describe "identities.facts.query.req ciphertext based" do
      let(:encryption_client) { double("encryption_client") }
      let(:input) { double("input",
        ciphertext: '{"protected": "header", "payload":"identities.facts.query.req"}',
        sender: "1112223334" ) }
      let(:typ) { "identities.facts.query.req" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"identities.facts.query.req","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("header").and_return('{"kid":"kid"}').once
        expect(jwt).to receive(:decode).with("identities.facts.query.req").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(messaging).to receive(:encryption_client).and_return(encryption_client).once
        expect(encryption_client).to receive(:decrypt).with("{\"protected\": \"header\", \"payload\":\"identities.facts.query.req\"}", "1112223334", "1112223334", 0).and_return("{\"protected\": \"header\", \"payload\":\"identities.facts.query.req\"}")
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_key).and_return(double(raw_public_key: "pk1"))
        expect(input).to receive(:offset).and_return(0)
        res = SelfSDK::Messages.parse(input, messaging)
        assert_equal res.class, SelfSDK::Messages::FactRequest
      end
    end

    describe "chat.message" do
      let(:input) { '{"protected": "header", "payload":"chat.message"}' }
      let(:typ) { "chat.message" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"chat.message","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("header").and_return('{"kid":"kid"}').once
        expect(jwt).to receive(:decode).with("chat.message").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_key).and_return(double(raw_public_key: "pk1"))
        res = SelfSDK::Messages.parse(input, messaging)
        assert_equal res.class, SelfSDK::Messages::ChatMessage
      end
    end

    describe "chat.message.delivered" do
      let(:input) { '{"protected": "header", "payload":"chat.message.delivered"}' }
      let(:typ) { "chat.message.delivered" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"chat.message.delivered","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("header").and_return('{"kid":"kid"}').once
        expect(jwt).to receive(:decode).with("chat.message.delivered").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_key).and_return(double(raw_public_key: "pk1"))
        res = SelfSDK::Messages.parse(input, messaging)
        assert_equal res.class, SelfSDK::Messages::ChatMessageDelivered
      end
    end

    describe "chat.message.read" do
      let(:input) { '{"protected": "header", "payload":"chat.message.read"}' }
      let(:typ) { "chat.message.read" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"chat.message.read","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("header").and_return('{"kid":"kid"}').once
        expect(jwt).to receive(:decode).with("chat.message.read").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_key).and_return(double(raw_public_key: "pk1"))
        res = SelfSDK::Messages.parse(input, messaging)
        assert_equal res.class, SelfSDK::Messages::ChatMessageRead
      end
    end

    describe "chat.invite" do
      let(:input) { '{"protected": "header", "payload":"chat.invite"}' }
      let(:typ) { "chat.invite" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"chat.invite","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("header").and_return('{"kid":"kid"}').once
        expect(jwt).to receive(:decode).with("chat.invite").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_key).and_return(double(raw_public_key: "pk1"))
        res = SelfSDK::Messages.parse(input, messaging)
        assert_equal res.class, SelfSDK::Messages::ChatInvite
      end
    end

    describe "chat.remove" do
      let(:input) { '{"protected": "header", "payload":"chat.remove"}' }
      let(:typ) { "chat.remove" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"chat.remove","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("header").and_return('{"kid":"kid"}').once
        expect(jwt).to receive(:decode).with("chat.remove").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_key).and_return(double(raw_public_key: "pk1"))
        res = SelfSDK::Messages.parse(input, messaging)
        assert_equal res.class, SelfSDK::Messages::ChatRemove
      end
    end

    describe "chat.join" do
      let(:input) { '{"protected": "header", "payload":"chat.join"}' }
      let(:typ) { "chat.join" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"chat.join","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("header").and_return('{"kid":"kid"}').once
        expect(jwt).to receive(:decode).with("chat.join").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_key).and_return(double(raw_public_key: "pk1"))
        res = SelfSDK::Messages.parse(input, messaging)
        assert_equal res.class, SelfSDK::Messages::ChatJoin
      end
    end

  end
end
