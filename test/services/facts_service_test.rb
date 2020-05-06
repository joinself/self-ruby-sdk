# frozen_string_literal: true

require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfid'

require 'webmock/minitest'

class SelfidTest < Minitest::Test
  describe "facts service" do
    let(:cid) {'cid'}
    let(:app_device_id) {'1'}
    let(:selfid) {'user_self_id'}
    let(:appid) { 'app_self_id' }
    let(:url) { 'https://my.app.com' }
    let(:json_body) { '{}' }
    let(:devices) { ["1", "2"]}
    let(:jwt) do
      j = double("jwt")
      expect(j).to receive(:id).and_return(appid).at_least(:twice)
      expect(j).to receive(:prepare).at_least(:once) do |arg|
        assert_equal arg[:typ], "identity_info_req"
        assert_equal arg[:iss], "app_self_id"
        assert_equal arg[:sub], "user_self_id"
        assert_equal arg[:facts].length, 2
        assert_equal arg[:facts].first[:fact], "email_address"
        assert_equal arg[:facts].last[:fact], "display_name"
      end.and_return(json_body)
      j
    end
    let(:client) do
      mm = double("client")
      expect(mm).to receive(:jwt).and_return(jwt).at_least(:once)
      mm
    end
    let(:messaging) do
      mm = double("messaging")
      expect(mm).to receive(:client).and_return(client)
      mm
    end
    let(:service) { Selfid::Services::Facts.new(messaging, client) }
    let(:response_input) { 'input' }
    let(:response) { double("response", input: response_input, uuid: cid, selfid: selfid) }
    let(:identity) { { public_keys: [ { key: "pk1"} ] } }

    def test_get_request_body
      req = service.request(selfid, ["email_address", "display_name"], request: false)
      assert_equal json_body, req
    end

    def test_non_blocking_request
      expect(messaging).to receive(:set_observer).once
      expect(messaging).to receive(:device_id).and_return("1").once
      expect(client).to receive(:devices).and_return(devices)
      expect(messaging).to receive(:send_message) do |arg|
        assert_equal arg.type, :MSG
        assert_equal arg.id, cid
        assert_equal arg.sender, "#{appid}:1"
        assert_equal arg.recipient, "#{selfid}:#{devices.first}"
        assert_equal arg.ciphertext, '{}'
      end.and_return(json_body)

      res = service.request selfid, ["email_address", "display_name"], cid: cid do
        assert_true true
      end
      assert_equal json_body, res
    end

    def test_blocking_request
      expect(messaging).to receive(:device_id).once.and_return("1")
      expect(messaging).to receive(:send_and_wait_for_response).once.and_return("response")
      expect(client).to receive(:devices).and_return(devices)

      res = service.request selfid, ["email_address", "display_name"], cid: cid
      assert_equal "response", res
    end

    def test_generate_qr
      res = service.generate_qr(["email_address", "display_name"], cid: cid, selfid: selfid)
      assert_equal RQRCode::QRCode, res.class
    end

    def test_intermediary_request
      expect(messaging).to receive(:set_observer).once
      expect(messaging).to receive(:device_id).and_return("1").once
      expect(client).to receive(:devices).and_return(devices)
      expect(messaging).to receive(:send_message) do |arg|
        assert_equal arg.type, :MSG
        assert_equal arg.id, cid
        assert_equal arg.sender, "#{appid}:1"
        assert_equal arg.recipient, "#{selfid}:#{devices.first}"
        assert_equal arg.ciphertext, '{}'
      end.and_return(json_body)

      res = service.request selfid, ["email_address", "display_name"], cid: cid do
        assert_true true
      end
      assert_equal json_body, res
    end
  end
end
