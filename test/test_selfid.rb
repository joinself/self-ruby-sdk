# frozen_string_literal: true

require 'minitest/autorun'
require 'selfid'

require 'webmock/minitest'
require 'timecop'

class SelfidTest < Minitest::Test
  describe "selfid" do
    let(:seed)    { "JDAiDNIZ0b7QOK3JNFp6ZDFbkhDk+N3NJh6rQ2YvVFI" }
    let(:app_id)  { "o9mpng9m2jv" }
    let(:app)     { Selfid::App.new(app_id, seed, messaging_url: nil) }
    let(:atoken)    { app.jwt.auth_token }
    let(:headers) {
      {
        'Content-Type' => 'application/json',
      }
    }

    def setup
      messaging_mock = Minitest::Mock.new
      def messaging_mock.device_id; "1"; end
      app.messaging = messaging_mock

      ENV["RAKE_ENV"] = "test"
      t = ::Time.local(2019, 9, 1, 10, 5, 0).utc
      Timecop.travel(t)
    end

    def teardown
      Timecop.return
    end

    def test_init_with_defaults
      assert_equal "https://api.review.selfid.net", app.client.self_url
      assert_equal app_id, app.jwt.id
      assert_equal seed, app.jwt.key
    end

    def test_init_with_custom_parameters
      custom_app = Selfid::App.new(app_id, seed, self_url: "http://custom.self.net", messaging_url: nil)
      assert_equal "http://custom.self.net", custom_app.client.self_url
      assert_equal app_id, custom_app.jwt.id
      assert_equal seed, custom_app.jwt.key
    end

    def test_authenticate
      body = "{\"payload\":\"eyJkZXZpY2VfaWQiOiIxIiwidHlwIjoiYXV0aGVudGljYXRpb25fcmVxIiwiYXVkIjoiaHR0cHM6Ly9hcGkucmV2aWV3LnNlbGZpZC5uZXQiLCJpc3MiOiJvOW1wbmc5bTJqdiIsInN1YiI6Inh4eHh4eHh4IiwiaWF0IjoiMjAxOS0wOS0wMVQxMDowNTowMFoiLCJleHAiOiIyMDE5LTA5LTAxVDExOjA1OjAwWiIsImNpZCI6InV1aWQiLCJqdGkiOiJ1dWlkIiwiY2FsbGJhY2siOiJodHRwOi8vbG9jYWxob3N0OjMwMDAvY2FsbGJhY2sifQ\",\"protected\":\"eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9\",\"signature\":\"C6qYtU_c417CII_j1bMe6INdzr5HXux-JIOMyYFWLeWUdy7HwogNGe5C-6ClsMEBLwVJMLSlo2wc7FdDa8ipBA\"}"
      stub_request(:post, "https://api.review.selfid.net/v1/auth").
        with(body: body, headers: headers).
        to_return(status: 200, body: "", headers: {})

      app.authenticate("xxxxxxxx", uuid: "uuid", jti: "uuid", callback: "http://localhost:3000/callback")
    end

    def test_identity
      pk = "pk_111222333"
      id = "111222333"

      stub_request(:get, "https://api.review.selfid.net/v1/apps/#{id}").
        with(headers: headers).
        to_return(status: 200, body: '{"public_keys":[{"id":"1","key":"' + pk + '"}]}', headers: {})

      identity = app.identity(id)
      assert_equal pk, identity[:public_keys].first[:key]
    end
  end
end
