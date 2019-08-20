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
    let(:atoken)    { "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJvOW1wbmc5bTJqdiJ9.jAZKnafk7HtxK3WfilkcTw6EwE1Ny3mHBbzf4eezG/Np9IB7I8GxJf921mCkcuAKBkSgIBMrUui+VYnaZSPYDQ" }
    let(:app)       { Selfid::App.new(app_id, seed) }
    let(:protected) { "eyJhbGciOiJFZERTQSJ9" }
    let(:headers) {
      {
        'Authorization' => "Bearer #{atoken}",
        'Content-Type' => 'application/json',
      }
    }

    def test_failed_authenticated?
      # invalid input
      assert_equal false, app.authenticated?("xxx")
      # valid json input
      assert_equal false, app.authenticated?("{}")
      # valid payload
      assert_equal false, app.authenticated?('{"payload":"xxx","protected":"xxx","signature":"xxxx"}')
    end

    def test_invalid_signature
      user_id = "user_id"

      stub_request(:get, "https://api.selfid.net/v1/identities/#{user_id}").
        with(headers: headers).
        to_return(status: 404, body: '', headers: {})

      payload = app.send(:encode, '{"sub":"' + user_id + '","isi":"self_id","status":"accepted"}')
      signature = app.send(:sign, "xoxo")

      body = "{\"payload\":\"#{payload}\",\"protected\":\"#{protected}\",\"signature\":\"#{signature}\"}"

      assert_equal false, app.authenticated?(body)
    end

    def test_non_existing_identity
      user_id = "user_id"

      stub_request(:get, "https://api.selfid.net/v1/identities/#{user_id}").
        with(headers: headers).
        to_return(status: 404, body: '', headers: {})

      payload = app.send(:encode, '{"sub":"' + user_id + '","isi":"self_id","status":"accepted"}')

      signature = app.send(:sign, "#{payload}.#{protected}")

      body = "{\"payload\":\"#{payload}\",\"protected\":\"#{protected}\",\"signature\":\"#{signature}\"}"

      assert_equal false, app.authenticated?(body)
    end

    def test_happy_path
      @keypair = Ed25519.provider.create_keypair(Base64.decode64(seed))
      pk = Ed25519::VerifyKey.new(@keypair[32, 32])
      pk = app.send(:encode, pk)
      user_id = "user_id"

      stub_request(:get, "https://api.selfid.net/v1/identities/#{user_id}").
        with(headers: headers).
        to_return(status: 200, body: '{"public_keys":[{"id":"1","key":"' + pk + '"}]}', headers: {})

      payload = app.send(:encode, '{"sub":"' + user_id + '","isi":"self_id","status":"accepted"}')

      signature = app.send(:sign, "#{payload}.#{protected}")

      body = "{\"payload\":\"#{payload}\",\"protected\":\"#{protected}\",\"signature\":\"#{signature}\"}"

      assert_equal true, app.authenticated?(body)
    end
  end
end
