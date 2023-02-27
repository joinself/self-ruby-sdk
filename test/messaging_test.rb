# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'test_helper'
require 'selfsdk'
require 'self_msgproto'
require "ed25519"

require 'webmock/minitest'
require 'timecop'

class SelfSDKTest < Minitest::Test
  describe "send" do
    let(:body) { '{"my":"payload"}' }
    let(:ws)   { double("ws") }
    let(:jwt)  { SelfSDK::JwtService.new("o9mpng9m2jv", "JDAiDNIZ0b7QOK3JNFp6ZDFbkhDk+N3NJh6rQ2YvVFI"); }
    let(:client) { double("client", jwt: jwt) }
    let(:storage_dir) { "/tmp/#{SecureRandom.uuid}" }

    let(:messaging_client) do
      SelfSDK::MessagingClient.new("", client, "", storage_dir: storage_dir, ws: ws, no_crypto: true)
    end

    def test_notify_observer_type
      messaging_client.type_observer[SelfSDK::Messages::FactResponse::MSG_TYPE] = {block: Proc.new do |res|
        assert_equal res.typ, SelfSDK::Messages::FactResponse::MSG_TYPE
      end }
      message = SelfSDK::Messages::FactResponse.new(messaging_client)
      messaging_client.send(:notify_observer, message)
    end

    def test_notify_observer_uuid
      messaging_client.uuid_observer["lol"] = { block: Proc.new do |input|
        assert_equal SelfSDK::Messages::FactResponse::MSG_TYPE, input.typ
        assert_equal "lol", input.id
      end }
      message = SelfSDK::Messages::FactResponse.new(messaging_client)
      message.id = "lol"
      messaging_client.send(:notify_observer, message)
    end

    def test_clean_timeouts
      messaging_client.instance_variable_get(:@acks)['uuid1'] = {
          waiting_cond: messaging_client.instance_variable_get(:@mon).new_cond,
          waiting: true,
          timeout: SelfSDK::Time.now - 150,
      }
      messaging_client.instance_variable_get(:@acks)['uuid2'] = {
          waiting_cond: messaging_client.instance_variable_get(:@mon).new_cond,
          waiting: true,
          timeout: SelfSDK::Time.now + 150,
      }
      messaging_client.instance_variable_get(:@messages)['uuid1'] = {
          waiting_cond: messaging_client.instance_variable_get(:@mon).new_cond,
          waiting: true,
          timeout: SelfSDK::Time.now - 150,
      }
      messaging_client.instance_variable_get(:@messages)['uuid2'] = {
          waiting_cond: messaging_client.instance_variable_get(:@mon).new_cond,
          waiting: true,
          timeout: SelfSDK::Time.now + 150,
      }
      messaging_client.send(:clean_timeouts)
      assert_equal false, messaging_client.instance_variable_get(:@messages)['uuid1'][:waiting]
      assert_equal true, messaging_client.instance_variable_get(:@messages)['uuid2'][:waiting]
      assert_equal false, messaging_client.instance_variable_get(:@acks)['uuid1'][:waiting]
      assert_equal true, messaging_client.instance_variable_get(:@acks)['uuid2'][:waiting]
    end

  end
end
