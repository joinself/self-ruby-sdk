# frozen_string_literal: true

require 'minitest/autorun'
require 'selfid'
require "ed25519"

require 'webmock/minitest'
require 'timecop'

class SelfidTest < Minitest::Test
  describe "authenticated?" do
    let(:seed)      { "JDAiDNIZ0b7QOK3JNFp6ZDFbkhDk+N3NJh6rQ2YvVFI" }
    let(:app_id)    { "o9mpng9m2jv" }
    let(:app)       { Selfid::App.new(app_id, seed, messaging_url: nil) }
    let(:atoken)    { app.jwt.auth_token }
    let(:protected_field) { app.jwt.send(:header) }
    let(:headers) {
      {
        'Content-Type' => 'application/json',
      }
    }

    def test_failed_authenticated?
      # invalid input
      assert_equal false, app.authenticated?("xxx").accepted?
      # valid json input
      assert_equal false, app.authenticated?("{}").accepted?
      # valid payload
      assert_equal false, app.authenticated?('{"payload":"xxx","protected":"xxx","signature":"xxxx"}').accepted?
    end

    def test_invalid_signature
      user_id = "user_id"
      stub_request(:get, "https://api.review.selfid.net/v1/apps/#{user_id}").
        with(headers: headers).
        to_return(status: 404, body: '{"message":"errored from tests"}', headers: {})

      payload = app.jwt.send(:encode, '{"sub":"' + user_id + '","iss":"self_id","status":"accepted"}')
      signature = app.jwt.send(:sign, "xoxo")

      body = "{\"payload\":\"#{payload}\",\"protected\":\"#{protected_field}\",\"signature\":\"#{signature}\"}"

      auth = app.authenticated?(body)
      assert_equal false, auth.accepted?
    end

    def test_non_existing_identity
      user_id = "user_id"
      stub_request(:get, "https://api.review.selfid.net/v1/apps/#{user_id}").
        with(headers: headers).
        to_return(status: 404, body: '{"message":"errored from tests"}', headers: {})

      payload = app.jwt.send(:encode, '{"sub":"' + user_id + '","iss":"self_id","status":"accepted"}')

      signature = app.jwt.send(:sign, "#{payload}.#{protected_field}")

      body = "{\"payload\":\"#{payload}\",\"protected\":\"#{protected_field}\",\"signature\":\"#{signature}\"}"

      authenticated = app.authenticated?(body)
      assert_equal false, authenticated.accepted?
    end

    def test_happy_path
      @keypair = Ed25519.provider.create_keypair(app.jwt.decode(seed))
      uuid = "uuid"
      pk = Ed25519::VerifyKey.new(@keypair[32, 32])
      pk = app.jwt.encode(pk)
      user_id = "user_id"

      stub_request(:get, "https://api.review.selfid.net/v1/apps/#{user_id}").
        with(headers: headers).
        to_return(status: 200, body: '{"public_keys":[{"id":"1","key":"' + pk + '"}]}', headers: {})

      body = app.jwt.prepare( sub: user_id,
                              iss: "self_id",
                              status: "accepted",
                              cid: uuid )

      auth = app.authenticated?(body)
      assert_equal true, auth.accepted?
      assert_equal uuid, auth.uuid
    end
  end
end
