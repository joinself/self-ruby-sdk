# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'test_helper'
require 'selfsdk'
require 'self_msgproto'
require "ed25519"

require 'webmock/minitest'
require 'timecop'

class SelfCryptoTest < Minitest::Test
  describe "send" do
    let(:url) {  "https://api.joinself.com" }

    let(:alice_storage_dir)  { "/tmp/test_alice" }
    let(:john_storage_dir)  { "/tmp/test_john" }
    let(:storage_key) { "kk" }

    let(:alice_id) { "alice" }
    let(:alice_device) { "1" }
    let(:alice_pubkey) { "lVlTp32Gc3KgMKfoDX-7lrZSdSO14BoXqoqnCKHWhzI" }
    let(:alice_key) { "1:DfTZU4US0GV+qLljNmatUOzJhi+xf2wRQMGR6TwTP1E" }
    let(:alice_jwt)  { SelfSDK::JwtService.new(alice_id, alice_key); }
    let(:alice_device_public_key) { double("alice_device_public_key", raw_public_key: alice_pubkey) }
    let(:alice_client) { double("alice_client", jwt: alice_jwt, device_public_key: alice_key) }
    let(:alice) do
      expect(alice_client).to receive(:post) do |url, prekeys|
        assert_equal "/v1/apps/#{alice_id}/devices/#{alice_device}/pre_keys", url
      end.and_return(double("response", status: 200, body: {"success": true}.to_json, code: 200))

      alice_storage = SelfSDK::Storage.new(alice_id, alice_device, alice_storage_dir, storage_key)
      SelfSDK::Crypto.new(alice_client, alice_device, alice_storage, storage_key)
    end

    let(:john_id) { "john" }
    let(:john_device) { "1" }
    let(:john_key) { "1:njXy0MxOEJ18GT2ilvejiCz3ZjGb+ID4klRd9siBb1w" }
    let(:john_pubkey) { "Is6sWRqs20R-8ZjgI-nIyGuOkZvPS-BQJdNZBJesd7M" }
    let(:john_jwt)  { SelfSDK::JwtService.new(john_id, john_key); }
    let(:john_device_public_key) { double("john_device_public_key", raw_public_key: john_pubkey) }
    let(:john_client) { double("john_client", jwt: john_jwt, device_public_key: alice_device_public_key) }

    let(:john) do
      expect(john_client).to receive(:post) do |url, prekeys|
        assert_equal "/v1/apps/#{john_id}/devices/#{john_device}/pre_keys", url
      end.and_return(double("response", status: 200, body: {"success": true}.to_json, code: 200))

      john_storage = SelfSDK::Storage.new(john_id, john_device, john_storage_dir, storage_key)
      SelfSDK::Crypto.new(john_client, john_device, john_storage, storage_key)
    end

    def setup
      FileUtils.rm_rf(alice_storage_dir)
      FileUtils.rm_rf(john_storage_dir)
    end

    def teardown
      FileUtils.rm_rf(alice_storage_dir)
      FileUtils.rm_rf(john_storage_dir)
    end

    def test_send_messages_back_and_forward
      # john_keys = john.instance_eval{ @keys }
      alice_keys = alice.instance_eval{ @keys }

      expect(john_client).to receive(:get) do |uri|
        assert_equal "/v1/identities/#{alice_id}/devices/#{alice_device}/pre_keys", uri
      end.and_return(double("response", status: 200, body: alice_keys[0].to_json, code: 200))


      body = "hello world"
      encrypted_body = john.encrypt(body, [{ id: alice_id, device_id: alice_device }])
      decrypted_body = alice.decrypt(encrypted_body, john_id, john_device)
      assert_equal body, decrypted_body

      body2 = "hello world 2"
      encrypted_body = alice.encrypt(body2, [{ id: john_id, device_id: john_device }])

      decrypted_body = john.decrypt(encrypted_body, alice_id, alice_device)
      assert_equal body2, decrypted_body
    end

    def test_send_multiple_messages_one_way_followed_by_a_reply
      # john_keys = john.instance_eval{ @keys }
      alice_keys = alice.instance_eval{ @keys }

      expect(john_client).to receive(:get) do |uri|
        assert_equal "/v1/identities/#{alice_id}/devices/#{alice_device}/pre_keys", uri
      end.and_return(double("response", status: 200, body: alice_keys[0].to_json, code: 200))

      50.times do |i|
        body = "hello world #{i}"
        encrypted_body = john.encrypt(body, [{ id: alice_id, device_id: alice_device }])
        decrypted_body = alice.decrypt(encrypted_body, john_id, john_device)
        assert_equal body, decrypted_body  
      end

      body2 = "response"
      encrypted_body = alice.encrypt(body2, [{ id: john_id, device_id: john_device }])
      decrypted_body = john.decrypt(encrypted_body, alice_id, alice_device)
      assert_equal body2, decrypted_body
    end
  end
end