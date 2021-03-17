# Copyright 2020 Self Group Ltd. All Rights Reserved.

require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfsdk'

require 'webmock/minitest'

class SelfSDKTest < Minitest::Test
  describe 'SelfSDK::Services::Identity' do
    let(:url) {  "https://api.joinself.com" }
    let(:id) { "o9mpng9m2jv" }
    let(:key) { "JDAiDNIZ0b7QOK3JNFp6ZDFbkhDk+N3NJh6rQ2YvVFI" }
    let(:headers) {
      {
          'Content-Type' => 'application/json',
      }
    }
    let(:client) { SelfSDK::RestClient.new(url, id, key, "") }

    subject{ SelfSDK::Services::Identity.new(client) }

    def setup
      ENV["RAKE_ENV"] = "test"
      t = ::Time.local(2019, 9, 1, 10, 5, 0).utc
      Timecop.travel(t)
    end

    def teardown
      Timecop.return
    end

    describe "score" do
      let(:selfid) { "1112223334" }
      let(:res_body) { {score: 10 } }
      let(:bearer) { "Bearer eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJqdGkiOiI5ZTVmMGQ3MC03YTY3LTQ5NjUtODQyMy0xNWE0ODVmMWQzYjEiLCJpYXQiOjE1NjczMzIyOTUsImV4cCI6MTU2NzMzMjM2MCwiaXNzIjoibzltcG5nOW0yanYifQ.SzlcYvCJcrkwSj_RhwU5mYqSc3v1gguJcSs_icokN26tSww6puSmHW9wzdTNJIfq2m7mQ3N4kcmstg4WNgGgAg" }
      def test_parse
        stub_request(:get, "#{url}/v1/identities/#{selfid}/score").with do |request|
          assert_nil request.body
          token = request.headers['Authorization'].split(" ").last.split(".")[1]
          req = JSON.parse(Base64.urlsafe_decode64(token))
          assert_equal "o9mpng9m2jv", req['iss']
          assert !req['jti'].empty?
        end.to_return(status: 200, body: res_body.to_json, headers: {})

        assert_equal 10, subject.score(selfid)
      end
    end

    describe "score with error" do
      let(:selfid) { "1112223334" }
      let(:res_body) { {message: "something happened", error_code: 200} }
      let(:bearer) { "Bearer eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJqdGkiOiI5ZTVmMGQ3MC03YTY3LTQ5NjUtODQyMy0xNWE0ODVmMWQzYjEiLCJpYXQiOjE1NjczMzIyOTUsImV4cCI6MTU2NzMzMjM2MCwiaXNzIjoibzltcG5nOW0yanYifQ.SzlcYvCJcrkwSj_RhwU5mYqSc3v1gguJcSs_icokN26tSww6puSmHW9wzdTNJIfq2m7mQ3N4kcmstg4WNgGgAg" }
      def test_parse
        stub_request(:get, "#{url}/v1/identities/#{selfid}/score").with do |request|
          assert_nil request.body
          token = request.headers['Authorization'].split(" ").last.split(".")[1]
          req = JSON.parse(Base64.urlsafe_decode64(token))
          assert_equal "o9mpng9m2jv", req['iss']
          assert !req['jti'].empty?
        end.to_return(status: 404, body: res_body.to_json, headers: {})

        assert_raises Exception do 
          subject.score(selfid)
        end
      end
    end

  end
end