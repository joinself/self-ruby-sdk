# Copyright 2020 Self Group Ltd. All Rights Reserved.

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
        assert_equal "identities.facts.query.req", arg[:typ]
        # TODO: this is failing.... 
        assert_equal selfid, arg[:aud]
        assert_equal appid, arg[:iss]
        assert_equal selfid, arg[:sub]
        assert_equal cid, arg[:cid]
        assert_equal true, arg[:auth]
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
      mm = double("messaging", source: SelfSDK::Sources.new("#{__dir__}/../../lib/sources.json"))
      expect(mm).to receive(:client).and_return(client)
      mm
    end
    let(:messaging_service) do
      mm = double("messaging_service")
      expect(mm).to receive(:client).and_return(messaging)
      mm
    end
    let(:requester) do 
      SelfSDK::Services::Requester.new(messaging_service, client)
    end
    let(:service) { SelfSDK::Services::Authentication.new(requester) }
    let(:response_input) { 'input' }
    let(:response) { double("response", input: response_input) }
    let(:identity) { { public_keys: [ { key: "pk1"} ] } }
    let(:app) { { paid_actions: true } }
    let(:blocked_app) { { paid_actions: false } }

    it "test_get_request_body" do
      req = service.request(selfid, cid: cid, request: false)
      assert_equal json_body, req
    end

    it "test_non_blocking_request" do
      expect(messaging_service).to receive(:is_permitted?).and_return(true)
      expect(messaging).to receive(:device_id).and_return(app_device_id)
      expect(messaging).to receive(:set_observer).once
      expect(messaging).to receive(:send_message).and_return(cid)
      expect(messaging).to receive(:encryption_client).and_return(encryption_client).once
      expect(encryption_client).to receive(:encrypt).with("{}", [{ device_id: "1", id: "user_self_id" }]).and_return("{}")
      expect(client).to receive(:devices).and_return([app_device_id])
      expect(client).to receive(:app).and_return(app)

      res = service.request selfid, cid: cid do
        assert_true true
      end
      assert_equal cid, res
    end

    it "test_blocking_request" do
      expect(messaging_service).to receive(:is_permitted?).and_return(true)
      expect(messaging).to receive(:device_id).twice.and_return(app_device_id)
      expect(messaging).to receive(:send_and_wait_for_response).and_return(cid)
      expect(messaging).to receive(:encryption_client).and_return(encryption_client).once
      expect(encryption_client).to receive(:encrypt).with("{}", [{ device_id: "1", id: "user_self_id" }]).and_return("{}")
      expect(client).to receive(:devices).twice.and_return([app_device_id])
      expect(client).to receive(:app).and_return(app)

      res = service.request selfid, cid: cid
      assert_equal "cid", res
    end

    it "test_generate_qr" do
      res = service.generate_qr(selfid: selfid, cid: cid)
      assert_equal RQRCode::QRCode, res.class
    end

  end
end
