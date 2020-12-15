# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'test_helper'
require 'selfsdk'

require 'webmock/minitest'
require 'timecop'
require 'base64'

class SelfSDKTest < Minitest::Test
  describe "selfsdk" do
    let(:seed)    { "JDAiDNIZ0b7QOK3JNFp6ZDFbkhDk+N3NJh6rQ2YvVFI" }
    let(:app_id)  { "o9mpng9m2jv" }
    let(:messaging_client) { double("messaging", device_id: "1", list_acl_rules:["*"] ) }
    let(:app) do
      a = SelfSDK::App.new(app_id, seed, "", "", messaging_url: nil)
      a.messaging_client = messaging_client
      a
    end
    let(:atoken)    { app.jwt.auth_token }
    let(:headers) {
      {
        'Content-Type' => 'application/json',
      }
    }

    def setup
      ENV["RAKE_ENV"] = "test"
      t = ::Time.local(2019, 9, 1, 10, 5, 0).utc
      Timecop.travel(t)
    end

    def teardown
      Timecop.return
    end

    def test_init_with_defaults
      assert_equal "https://api.joinself.com", app.client.self_url
      assert_equal app_id, app.app_id
      assert_equal seed, app.app_key
    end

    def test_init_with_custom_parameters
      custom_app = SelfSDK::App.new(app_id, seed, "", "", base_url: "http://custom.self.net", messaging_url: nil)
      assert_equal "http://custom.self.net", custom_app.client.self_url
      assert_equal app_id, custom_app.app_id
      assert_equal seed, custom_app.app_key
    end

  end
end
