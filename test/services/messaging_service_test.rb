# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfsdk'

require 'webmock/minitest'

class SelfSDKTest < Minitest::Test
  describe 'messaging' do
    let(:appid) { 'app_self_id' }
    let(:json_body) { '{}' }
    let(:service) { SelfSDK::Services::Messaging.new(messaging) }
    let(:jwt) { double("jwt") }
    let(:messaging) do
      mm = double("messaging")
      expect(mm).to receive(:jwt).and_return(jwt)
      mm
    end

    describe "messaging service" do
      let(:cid) {'cid'}
      let(:app_device_id) {'1'}
      let(:selfid) {'user_self_id'}
      let(:url) { 'https://my.app.com' }
      let(:devices) { ["1", "2"]}
    end
  end
end
