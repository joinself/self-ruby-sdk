# frozen_string_literal: true

require_relative 'test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfid'

require 'webmock/minitest'

class SelfidTest < Minitest::Test
  describe 'messaging' do
    let(:appid) { 'app_self_id' }
    let(:json_body) { '{}' }
    let(:service) { Selfid::Services::Messaging.new(messaging) }
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

      def test_permit_connection
        expect(jwt).to receive(:id).and_return(appid).at_least(:once)
        expect(jwt).to receive(:prepare).at_least(:once) do |arg|
          assert_equal arg[:iss], appid
          assert_equal arg[:acl_source], selfid
        end.and_return(json_body)
        expect(messaging).to receive(:add_acl_rule).with(json_body).and_return(true).once
        req = service.permit_connection(selfid)
        assert_equal true, req
      end

      def test_revoke_connection
        expect(jwt).to receive(:id).and_return(appid).at_least(:once)
        expect(jwt).to receive(:prepare).at_least(:once) do |arg|
          assert_equal arg[:iss], appid
          assert_equal arg[:acl_source], selfid
        end.and_return(json_body)
        expect(messaging).to receive(:remove_acl_rule).with(json_body).and_return(true).once
        req = service.revoke_connection(selfid)
        assert_equal true, req
      end
    end

    describe 'allowed connections' do
      def test_allowed_connections
        expect(messaging).to receive(:list_acl_rules).and_return([{'acl_source' => appid,
                                                                   'acl_exp' => Time.now.to_s}]).once
        res = service.allowed_connections
        assert_equal 1, res.length
      end
    end
  end
end
