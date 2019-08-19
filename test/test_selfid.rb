# frozen_string_literal: true

require 'minitest/autorun'
require 'selfid'

require 'webmock/minitest'
require 'timecop'

class SelfidTest < Minitest::Test
  describe "selfid" do
    let(:seed) { "JDAiDNIZ0b7QOK3JNFp6ZDFbkhDk+N3NJh6rQ2YvVFI" }
    let(:app_id) { "o9mpng9m2jv" }
    let(:atoken) { "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJvOW1wbmc5bTJqdiJ9.jAZKnafk7HtxK3WfilkcTw6EwE1Ny3mHBbzf4eezG/Np9IB7I8GxJf921mCkcuAKBkSgIBMrUui+VYnaZSPYDQ" }

    def setup
      t = Time.local(2019, 9, 1, 10, 5, 0).utc
      Timecop.travel(t)
    end

    def teardown
      Timecop.return
    end

    describe "selfid::init" do
      def test_init_with_defaults
        app = Selfid::App.new(app_id, seed)
        assert_equal "https://api.selfid.net", app.self_url
        assert_equal app_id, app.app_id
        assert_equal seed, app.app_key
      end

      def test_init_with_custom_parameters
        app = Selfid::App.new(app_id, seed, self_url: "http://custom.self.net")
        assert_equal "http://custom.self.net", app.self_url
        assert_equal app_id, app.app_id
        assert_equal seed, app.app_key
      end
    end

    describe "auth_token" do
      def test_auth_token
        app = Selfid::App.new(app_id, seed)
        token = app.send(:auth_token)
        assert_equal atoken, token
      end
    end

    describe "authenticate" do
      def test_authenticate
        body = "{\"payload\":\"eyJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjMwMDAvY2FsbGJhY2siLCJhdWQiOiJodHRwczovL2FwaS5zZWxmaWQubmV0IiwiaXNpIjoibzltcG5nOW0yanYiLCJzdWIiOiJ4eHh4eHh4eCIsImp0aSI6InV1aWQifQ\",\"protected\":\"eyJ0eXAiOiJFZERTQSJ9\",\"signature\":\"0YRtbyNLfRezyukX8VcnX1OTFNk5UURlKgcf1yOo/diqbkMVmC6lLhRdo8HZkrsUe2jPAaOGQLs1J13qOJmSAw\"}"
        headers = {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => "Bearer #{atoken}",
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby'
        }
        stub_request(:post, "http://api.selfid.net:443/v1/auth").
          with(body: body, headers: headers).
          to_return(status: 200, body: "", headers: {})
        app = Selfid::App.new(app_id, seed)
        app.authenticate("xxxxxxxx", "http://localhost:3000/callback", uuid: "uuid")
      end
    end
  end
end
