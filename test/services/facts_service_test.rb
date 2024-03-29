# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfsdk'
require 'self_msgproto'

require 'webmock/minitest'

class SelfSDKTest < Minitest::Test
  describe "facts service" do
    let(:cid) {'cid'}
    let(:app_device_id) {'1'}
    let(:selfid) {'user_self_id'}
    let(:appid) { 'app_self_id' }
    let(:url) { 'https://my.app.com' }
    let(:json_body) { '{}' }
    let(:devices) { ["1"]}
    let(:app) { { paid_actions: true } }
    let(:jwt) do
      j = double("jwt")
      expect(j).to receive(:id).and_return(appid).at_least(:twice)
      expect(j).to receive(:prepare).at_least(:once) do |arg|
        assert_equal arg[:typ], subject_type
        assert_equal arg[:iss], "app_self_id"
        assert_equal arg[:sub], "user_self_id"
        if expected_facts
          assert_equal arg[:facts], expected_facts
        else
          assert_equal arg[:attestations], expected_attestations
          assert_equal arg[:viewers], expected_viewers if expected_viewers
        end
      end.and_return(json_body)
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
    let(:service) { SelfSDK::Services::Facts.new(requester) }
    let(:response_input) { 'input' }
    let(:response) { double("response", input: response_input, uuid: cid, selfid: selfid) }
    let(:identity) { { public_keys: [ { key: "pk1"} ] } }

    describe "fact queries" do
      let(:expected_facts) { [{ fact: "email_address" }, { fact: "display_name" }]}
      let(:subject_type) { "identities.facts.query.req" }

      it "test_get_request_body" do
        req = service.request(selfid, ["email_address", "display_name"], request: false)
        assert_equal json_body, req
      end

      it ":test_non_blocking_request" do
        expect(messaging).to receive(:set_observer).once
        expect(messaging).to receive(:device_id).and_return("1").once
        expect(messaging).to receive(:encryption_client).and_return(encryption_client).once
        expect(encryption_client).to receive(:encrypt).with("{}", [{ device_id: "1", id: "user_self_id" }]).and_return("{}")
        expect(client).to receive(:devices).and_return(devices).once
        expect(messaging).to receive(:send_message) do |arg|
          assert_equal arg.sender, "#{appid}:1"
          assert_equal arg.recipient, "#{selfid}:#{devices.first}"
          assert_equal arg.ciphertext, '{}'
        end.and_return(json_body)
        expect(client).to receive(:app).and_return(app)

        res = service.request selfid, ["email_address", "display_name"], cid: cid do
          assert_true true
        end
        assert_equal json_body, res
      end

      it ":test_blocking_request" do
        expect(messaging).to receive(:device_id).twice.and_return("1")
        expect(messaging).to receive(:send_and_wait_for_response).once.and_return("response")
        expect(messaging).to receive(:encryption_client).and_return(encryption_client).once
        expect(encryption_client).to receive(:encrypt).with("{}", [{ device_id: "1", id: "user_self_id" }]).and_return("{}")
        expect(client).to receive(:devices).twice.and_return(devices)
        expect(client).to receive(:app).and_return(app)

        res = service.request selfid, ["email_address", "display_name"], cid: cid
        assert_equal "response", res
      end

      it ":test_generate_qr" do
        res = service.generate_qr(["email_address", "display_name"], cid: cid, selfid: selfid)
        assert_equal RQRCode::QRCode, res.class
      end

      it ":test_intermediary_request" do
        expect(messaging).to receive(:set_observer).once
        expect(messaging).to receive(:device_id).and_return("1").once
        expect(messaging).to receive(:encryption_client).and_return(encryption_client).once
        expect(encryption_client).to receive(:encrypt).with("{}", [{ device_id: "1", id: "user_self_id" }]).and_return("{}")
        expect(client).to receive(:devices).and_return(devices).once
        expect(messaging).to receive(:send_message) do |arg|
          assert_equal arg.sender, "#{appid}:1"
          assert_equal arg.recipient, "#{selfid}:#{devices.first}"
          assert_equal arg.ciphertext, '{}'
        end.and_return(json_body)
        expect(client).to receive(:app).and_return(app)

        res = service.request selfid, ["email_address", "display_name"], cid: cid do
          assert_true true
        end
        assert_equal json_body, res
      end

    end

    describe "fact issue" do
      let(:expected_facts) { nil }
      let(:subject_type) { "identities.facts.issue" }
      let(:expected_attestations) { ['<my_signed_attestation>'] }
      let(:expected_viewers) { nil }
      it ":issue" do
        expect(jwt).to receive(:signed).and_return("<my_signed_attestation>")
        expect(client).to receive(:app).with("app_self_id").and_return({ paid_actions: true })
        expect(client).to receive(:devices).with("user_self_id").and_return(["1"])
        expect(messaging).to receive(:device_id).and_return("1").once
        expect(messaging).to receive(:encryption_client).and_return(encryption_client).once
        expect(encryption_client).to receive(:encrypt).with("{}", [{ device_id: "1", id: "user_self_id" }]).and_return("{}")
        expect(messaging).to receive(:send_message) do |arg|
          assert_equal arg.sender, "#{appid}:1"
          assert_equal arg.recipient, "#{selfid}:#{devices.first}"
          assert_equal arg.ciphertext, '{}'
        end.and_return(json_body)

        service.issue("user_self_id", [{ key: "my_fact", value: "tupu", source: "my_source" }])
      end
    end
  end
end
