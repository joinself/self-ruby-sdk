require_relative 'test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfid'

require 'webmock/minitest'

class SelfidTest < Minitest::Test
  describe 'Selfid::RestClient' do
    let(:url) {  "https://api.selfid.net" }
    let(:id) { "o9mpng9m2jv" }
    let(:key) { "JDAiDNIZ0b7QOK3JNFp6ZDFbkhDk+N3NJh6rQ2YvVFI" }
    let(:headers) {
      {
          'Content-Type' => 'application/json',
      }
    }

    subject{ Selfid::RestClient.new(url, id, key, "") }

    def setup
      ENV["RAKE_ENV"] = "test"
      t = ::Time.local(2019, 9, 1, 10, 5, 0).utc
      Timecop.travel(t)
    end

    def teardown
      Timecop.return
    end

    describe "devices" do
      let(:selfid) { "1112223334" }
      let(:res_body) { {message: 'yolo'} }
      let(:bearer) { "Bearer eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJqdGkiOiI5ZTVmMGQ3MC03YTY3LTQ5NjUtODQyMy0xNWE0ODVmMWQzYjEiLCJpYXQiOjE1NjczMzIyOTUsImV4cCI6MTU2NzMzMjM2MCwiaXNzIjoibzltcG5nOW0yanYifQ.SzlcYvCJcrkwSj_RhwU5mYqSc3v1gguJcSs_icokN26tSww6puSmHW9wzdTNJIfq2m7mQ3N4kcmstg4WNgGgAg" }
      def test_parse
        stub_request(:get, "#{url}/v1/identities/#{selfid}/devices").with do |request|
          assert_nil request.body
          token = request.headers['Authorization'].split(" ").last.split(".")[1]
          req = JSON.parse(Base64.urlsafe_decode64(token))
          assert_equal "o9mpng9m2jv", req['iss']
          assert !req['jti'].empty?
        end.to_return(status: 200, body: res_body.to_json, headers: {})

        assert_equal res_body, subject.devices(selfid)
      end
    end

  end
end