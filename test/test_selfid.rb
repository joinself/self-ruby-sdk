# frozen_string_literal: true

require 'minitest/autorun'
require 'selfid'

require 'webmock/minitest'
require 'timecop'

class SelfidTest < Minitest::Test
  describe "selfid" do
    let(:seed)    { "JDAiDNIZ0b7QOK3JNFp6ZDFbkhDk+N3NJh6rQ2YvVFI" }
    let(:app_id)  { "o9mpng9m2jv" }
    let(:atoken)  { "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJvOW1wbmc5bTJqdiJ9.jAZKnafk7HtxK3WfilkcTw6EwE1Ny3mHBbzf4eezG/Np9IB7I8GxJf921mCkcuAKBkSgIBMrUui+VYnaZSPYDQ" }
    let(:app)     { Selfid::App.new(app_id, seed) }
    let(:headers) {
      {
        'Authorization' => "Bearer #{atoken}",
        'Content-Type' => 'application/json',
      }
    }

    def setup
      t = Time.local(2019, 9, 1, 10, 5, 0).utc
      Timecop.travel(t)
    end

    def teardown
      Timecop.return
    end

    def test_init_with_defaults
      assert_equal "https://api.selfid.net", app.client.self_url
      assert_equal app_id, app.jwt.id
      assert_equal seed, app.jwt.key
    end

    def test_init_with_custom_parameters
      custom_app = Selfid::App.new(app_id, seed, self_url: "http://custom.self.net")
      assert_equal "http://custom.self.net", custom_app.client.self_url
      assert_equal app_id, custom_app.jwt.id
      assert_equal seed, custom_app.jwt.key
    end

    def test_auth_token
      token = app.jwt.send(:auth_token)
      assert_equal atoken, token
    end

    def test_authenticate
      body = "{\"payload\":\"eyJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjMwMDAvY2FsbGJhY2siLCJhdWQiOiJodHRwczovL2FwaS5zZWxmaWQubmV0IiwiaXNpIjoibzltcG5nOW0yanYiLCJzdWIiOiJ4eHh4eHh4eCIsImlhdCI6IjIwMTktMDktMDFUMTA6MDU6MDBaIiwiZXhwIjoiMjAxOS0wOS0wMVQxMTowNTowMFoiLCJqdGkiOiJ1dWlkIn0\",\"protected\":\"eyJ0eXAiOiJFZERTQSJ9\",\"signature\":\"2wR8O1rqTWnN9abaWs7lrbwLRBXGhDXSrIf/koAPfDF6FYWmcF3qZ1EHSqa9GQ1vvGvasatkGnJp5ovDWYqFDw\"}"
      stub_request(:post, "https://api.selfid.net/v1/auth").
        with(body: body, headers: headers).
        to_return(status: 200, body: "", headers: {})
      app.authenticate("xxxxxxxx", "http://localhost:3000/callback", uuid: "uuid")
    end

    def test_identity
      pk = "pk_111222333"
      id = "111222333"

      stub_request(:get, "https://api.selfid.net/v1/identities/#{id}").
        with(headers: headers).
        to_return(status: 200, body: '{"public_keys":[{"id":"1","key":"' + pk + '"}]}', headers: {})

      identity = app.identity(id)
      assert_equal pk, identity[:public_keys].first[:key]
    end
  end
end
