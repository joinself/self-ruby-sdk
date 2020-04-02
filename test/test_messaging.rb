# frozen_string_literal: true

require 'minitest/autorun'
require 'selfid'
require "ed25519"

require 'webmock/minitest'
require 'timecop'

class SelfidTest < Minitest::Test
  describe "send" do
    let(:body) { '{"my":"payload"}' }
    let(:ws)   { MiniTest::Mock.new }
    let(:client) do
      mm = Minitest::Mock.new
      def mm.jwt; Selfid::Jwt.new("o9mpng9m2jv", "JDAiDNIZ0b7QOK3JNFp6ZDFbkhDk+N3NJh6rQ2YvVFI"); end
      mm
    end

    let(:messaging_client) do
      Selfid::MessagingClient.new("", client, ws: ws)
    end

    def test_share_information

      ws.expect :send, "{}" do |msg|
        input = Msgproto::Message.decode(msg.pack('c*'))
        jwt = JSON.parse(input.ciphertext, symbolize_names: true)
        payload = JSON.parse(messaging_client.jwt.decode(jwt[:payload]), symbolize_names: true)
        assert_equal body, payload
        messaging_client.stop
      end

      messaging_client.share_information("john", "john_device", body)
    end


    def test_notify_observer_type
      messaging_client.type_observer[Selfid::Messages::AuthenticationResp::MSG_TYPE] = Proc.new do |input|
        assert_equal input.typ, Selfid::Messages::AuthenticationResp::MSG_TYPE
      end
      message = Selfid::Messages::AuthenticationResp.new(messaging_client)
      messaging_client.send(:notify_observer, message)
    end

    def test_notify_observer_uuid
      messaging_client.uuid_observer["lol"] = Proc.new do |input|
        assert_equal input.typ, Selfid::Messages::AuthenticationResp::MSG_TYPE
        assert_equal input.id, "lol"
      end
      message = Selfid::Messages::AuthenticationResp.new(messaging_client)
      message.id = "lol"
      messaging_client.send(:notify_observer, message)
    end

  end
end
