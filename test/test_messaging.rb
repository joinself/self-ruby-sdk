# frozen_string_literal: true

require 'minitest/autorun'
require 'selfid'
require "ed25519"

require 'webmock/minitest'
require 'timecop'

class SelfidTest < Minitest::Test
  describe "send" do
    let(:app_secret_key)  { "JDAiDNIZ0b7QOK3JNFp6ZDFbkhDk+N3NJh6rQ2YvVFI" }
    let(:app_id)          { "o9mpng9m2jv" }
    let(:body)            { '{"my":"payload"}' }
    let(:ws)              { MiniTest::Mock.new }
    let(:client) do
      url = ""
      selfid_client = nil

      jwt = Selfid::Jwt.new(app_id, app_secret_key)
      Selfid::MessagingClient.new(url, jwt, selfid_client, ws: ws)
    end

    def test_share_information

      ws.expect :send, "{}" do |msg|
        input = Msgproto::Message.decode(msg.pack('c*'))
        jwt = JSON.parse(input.ciphertext, symbolize_names: true)
        payload = JSON.parse(client.jwt.decode(jwt[:payload]), symbolize_names: true)
        assert_equal body, payload
        client.stop
      end

      client.share_information("john", "john_device", body)
    end


    def test_notify_observer
      client.type_observer[Selfid::Messages::AuthenticationResp::MSG_TYPE] = Proc.new do |input|
        assert_equal input.typ, Selfid::Messages::AuthenticationResp::MSG_TYPE
      end
      message = Selfid::Messages::AuthenticationResp.new(client)
      client.send(:notify_observer, message)
    end

  end
end
