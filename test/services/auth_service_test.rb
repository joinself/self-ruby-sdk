# frozen_string_literal: true

require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfsdk'

require 'webmock/minitest'

class SelfSDKTest < Minitest::Test
  describe "authentication service" do
    let(:cid) {'cid'}
    let(:app_device_id) {'1'}
    let(:selfid) {'user_self_id'}
    let(:appid) { 'app_self_id' }
    let(:url) { 'https://my.app.com' }
    let(:json_body) { '{}' }

    let(:jwt) do
      j = double("jwt")
      expect(j).to receive(:id).and_return(appid).at_least(2).times
      expect(j).to receive(:prepare) do |arg|
        assert_equal arg[:typ], "identities.authenticate.req"
        assert_equal arg[:aud], selfid
        assert_equal arg[:iss], appid
        assert_equal arg[:sub], selfid
        assert_equal arg[:cid], cid
      end.at_least(:once).and_return(json_body)
      j
    end
    let(:encryption_client) { double("encryption_client") }
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
    let(:messaging_service) do
      mm = double("messaging_service")
      expect(mm).to receive(:client).and_return(messaging)
      expect(mm).to receive(:is_permitted?).and_return(true)
      mm
    end
    let(:service) { SelfSDK::Services::Authentication.new(messaging_service, client) }
    let(:response_input) { 'input' }
    let(:response) { double("response", input: response_input) }
    let(:identity) { { public_keys: [ { key: "pk1"} ] } }

    def test_get_request_body
      req = service.request(selfid, cid: cid, request: false)
      assert_equal json_body, req
    end

    def test_non_blocking_request
      expect(messaging).to receive(:device_id).and_return(app_device_id)
      expect(messaging).to receive(:set_observer).once
      expect(messaging).to receive(:send_message).and_return(cid)
      expect(messaging).to receive(:encryption_client).and_return(encryption_client).once
      expect(encryption_client).to receive(:encrypt).with("{}", "user_self_id", "1").and_return("{}")
      expect(client).to receive(:devices).and_return([app_device_id])
      res = service.request selfid, cid: cid do
        assert_true true
      end
      assert_equal cid, res
    end

    def test_blocking_request
      expect(messaging).to receive(:device_id).and_return(app_device_id)
      expect(messaging).to receive(:send_and_wait_for_response).and_return(cid)
      expect(messaging).to receive(:encryption_client).and_return(encryption_client).once
      expect(encryption_client).to receive(:encrypt).with("{}", "user_self_id", "1").and_return("{}")
      expect(client).to receive(:devices).and_return([app_device_id])

      res = service.request selfid, cid: cid
      assert_equal "cid", res
    end

    def test_generate_qr
      res = service.generate_qr(selfid: selfid, cid: cid)
      assert_equal RQRCode::QRCode, res.class
    end

  end
end
