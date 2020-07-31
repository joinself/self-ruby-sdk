# frozen_string_literal: true

require_relative 'test_helper'
require 'selfid'
require "ed25519"

require 'webmock/minitest'
require 'timecop'

class SelfidTest < Minitest::Test
  describe "send" do
    let(:body) { '{"my":"payload"}' }
    let(:ws)   { double("ws") }
    let(:jwt)  { Selfid::JwtService.new("o9mpng9m2jv", "JDAiDNIZ0b7QOK3JNFp6ZDFbkhDk+N3NJh6rQ2YvVFI"); }
    let(:client) { double("client", jwt: jwt) }
    let(:storage_dir) { "/tmp/#{SecureRandom.uuid}" }

    let(:messaging_client) do
      Selfid::MessagingClient.new("", client, 'app_id', storage_dir: storage_dir, ws: ws)
    end

    def test_share_information
      expect(ws).to receive(:send) do |msg|
        input = Msgproto::Message.decode(msg.pack('c*'))
        jwt = JSON.parse(input.ciphertext, symbolize_names: true)
        payload = JSON.parse(messaging_client.jwt.decode(jwt[:payload]), symbolize_names: true)
        assert_equal body, payload
        messaging_client.stop
      end

      messaging_client.share_information("john", "john_device", body)
    end


    def test_notify_observer_type
      messaging_client.type_observer[Selfid::Messages::AuthenticationResp::MSG_TYPE] = {block: Proc.new do |res|
        assert_equal res.typ, Selfid::Messages::AuthenticationResp::MSG_TYPE
      end }
      message = Selfid::Messages::AuthenticationResp.new(messaging_client)
      messaging_client.send(:notify_observer, message)
    end

    def test_notify_observer_uuid
      messaging_client.uuid_observer["lol"] = { block: Proc.new do |input|
        assert_equal input.typ, Selfid::Messages::AuthenticationResp::MSG_TYPE
        assert_equal input.id, "lol"
      end }
      message = Selfid::Messages::AuthenticationResp.new(messaging_client)
      message.id = "lol"
      messaging_client.send(:notify_observer, message)
    end

    def test_clean_timeouts
      messaging_client.instance_variable_get(:@acks)['uuid1'] = {
          waiting_cond: messaging_client.instance_variable_get(:@mon).new_cond,
          waiting: true,
          timeout: Selfid::Time.now - 150,
      }
      messaging_client.instance_variable_get(:@acks)['uuid2'] = {
          waiting_cond: messaging_client.instance_variable_get(:@mon).new_cond,
          waiting: true,
          timeout: Selfid::Time.now + 150,
      }
      messaging_client.instance_variable_get(:@messages)['uuid1'] = {
          waiting_cond: messaging_client.instance_variable_get(:@mon).new_cond,
          waiting: true,
          timeout: Selfid::Time.now - 150,
      }
      messaging_client.instance_variable_get(:@messages)['uuid2'] = {
          waiting_cond: messaging_client.instance_variable_get(:@mon).new_cond,
          waiting: true,
          timeout: Selfid::Time.now + 150,
      }
      messaging_client.send(:clean_timeouts)
      assert_equal false, messaging_client.instance_variable_get(:@messages)['uuid1'][:waiting]
      assert_equal true, messaging_client.instance_variable_get(:@messages)['uuid2'][:waiting]
      assert_equal false, messaging_client.instance_variable_get(:@acks)['uuid1'][:waiting]
      assert_equal true, messaging_client.instance_variable_get(:@acks)['uuid2'][:waiting]
    end

  end
end
