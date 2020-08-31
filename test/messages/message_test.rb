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

    describe "identities.authenticate.resp" do
      let(:input) { '{"protected": "header", "payload":"identities.authenticate.resp"}' }
      let(:typ) { "identities.authenticate.resp" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"identities.authenticate.resp","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("header").and_return('{"kid":"kid"}').once
        expect(jwt).to receive(:decode).with("identities.authenticate.resp").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_key).and_return(double(raw_public_key: "pk1"))
        res = SelfSDK::Messages.parse(input, messaging)
        assert_equal res.class, SelfSDK::Messages::AuthenticationResp
      end
    end

    describe "identities.facts.query.req ciphertext based" do
      let(:input) { double("input", ciphertext: '{"protected": "header", "payload":"identities.facts.query.req"}') }
      let(:typ) { "identities.facts.query.req" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"identities.facts.query.req","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("header").and_return('{"kid":"kid"}').once
        expect(jwt).to receive(:decode).with("identities.facts.query.req").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_key).and_return(double(raw_public_key: "pk1"))
        res = SelfSDK::Messages.parse(input, messaging)
        assert_equal res.class, SelfSDK::Messages::FactRequest
      end
    end
  end
end
