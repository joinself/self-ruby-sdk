require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfid'

require 'webmock/minitest'

class SelfidTest < Minitest::Test
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
        _{ Selfid::Messages.parse(input, messaging) }.must_raise StandardError
      end
    end

    describe "identity_info_req" do
      let(:input) { '{"payload":"identity_info_req"}' }
      let(:typ) { "identity_info_req" }
      let(:client) { double("client") }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("identity_info_req").and_return('{"typ":"identity_info_req"}').twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_keys).and_return([{key: "pk1"}])
        res = Selfid::Messages.parse(input, messaging)
        assert_equal res.class, Selfid::Messages::FactRequest
      end
    end

    describe "identity_info_resp" do
      let(:input) { '{"payload":"identity_info_resp"}' }
      let(:typ) { "identity_info_resp" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"identity_info_resp","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("identity_info_resp").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_keys).and_return([{key: "pk1"}])
        res = Selfid::Messages.parse(input, messaging)
        assert_equal res.class, Selfid::Messages::FactResponse
      end
    end

    describe "authentication_resp" do
      let(:input) { '{"payload":"authentication_resp"}' }
      let(:typ) { "authentication_resp" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"authentication_resp","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("authentication_resp").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_keys).and_return([{key: "pk1"}])
        res = Selfid::Messages.parse(input, messaging)
        assert_equal res.class, Selfid::Messages::AuthenticationResp
      end
    end

    describe "identity_info_req ciphertext based" do
      let(:input) { double("input", ciphertext: '{"payload":"identity_info_req"}') }
      let(:typ) { "identity_info_req" }
      let(:client) { double("client") }
      let(:body) { '{"typ":"identity_info_req","exp":"'+exp+'","iat":"'+iat+'"}' }
      def test_parse_identity_info_req
        expect(jwt).to receive(:decode).with("identity_info_req").and_return(body).twice
        expect(jwt).to receive(:verify).and_return(true)
        expect(messaging).to receive(:client).and_return(client)
        expect(messaging).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:jwt).and_return(jwt)
        expect(client).to receive(:public_keys).and_return([{key: "pk1"}])
        res = Selfid::Messages.parse(input, messaging)
        assert_equal res.class, Selfid::Messages::FactRequest
      end
    end
  end
end
