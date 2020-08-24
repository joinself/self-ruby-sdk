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
    let(:messaging_client) { double("messaging", device_id: "1") }
    let(:app) do
      a = SelfSDK::App.new(app_id, seed, "", messaging_url: nil)
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
      custom_app = SelfSDK::App.new(app_id, seed, "",base_url: "http://custom.self.net", messaging_url: nil)
      assert_equal "http://custom.self.net", custom_app.client.self_url
      assert_equal app_id, custom_app.app_id
      assert_equal seed, custom_app.app_key
    end

    def test_authenticate
      jwt = double("jwt", id: "appid")
      client = double("client", jwt: jwt)
      expect(app.messaging_client).to receive(:client).and_return(client)
      res = JSON.parse(app.authentication.request("xxxxxxxx", cid: "uuid", jti: "uuid", request: false))
      payload = JSON.parse(Base64.urlsafe_decode64(res['payload']))
      assert_equal "appid", payload['iss']
      assert_equal "identities.authenticate.req", payload['typ']
      assert_equal "xxxxxxxx", payload['sub']
      assert_equal "xxxxxxxx", payload['aud']
      assert_equal "uuid", payload['cid']
    end

    def test_public_keys
      pk = "pk_111222333"
      id = "11122233344"

      stub_request(:get, "https://api.joinself.com/v1/identities/#{id}").
        with(headers: headers).
        to_return(status: 200, body: '{"public_keys":[{"id":"1","key":"' + pk + '"}]}', headers: {})

      pks = app.identity.public_keys(id)
      assert_equal pk, pks.first[:key]
    end

  end
end
