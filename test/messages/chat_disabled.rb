# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true
require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'

require 'webmock/minitest'

class ChatMessageTest < Minitest::Test
  describe 'build_from_data' do
    let(:identity_key) { "xxxx" }

    describe "parse" do
      let(:messaging) { double("messaging") }
      let(:input) { '{"payload":"eyJ0eXAiOiJjaGF0Lmludml0ZSIsImdpZCI6Imdyb3VwMSIsInN1YiI6IjdkNDllYzcyLTI5Y2ItNDQxNy05YjA5LTYyNjBkY2I2MjQwZSIsIm5hbWUiOiJBcHBzR3JvdXAiLCJtZW1iZXJzIjpbIjNiMmIxNWY4LTFjZDktNDE4YS1iMWE0LTljMTUxZjUzYTQ3MSIsIjdkNDllYzcyLTI5Y2ItNDQxNy05YjA5LTYyNjBkY2I2MjQwZSIsIjg0ODYxNDg2NDc2Il0sImp0aSI6IjY5OTM0NDdlLTg2NjItNGVlNy04ZDk3LTJjNzU3NmFhOWVmNiIsImlzcyI6IjdkNDllYzcyLTI5Y2ItNDQxNy05YjA5LTYyNjBkY2I2MjQwZSIsImlhdCI6IjIwMjItMDEtMDRUMTM6NTc6NThaIiwiZXhwIjoiMjAyMi0wMS0wNFQxNDowMjo1OFoiLCJjaWQiOiI3NDkxNjkxYS1iYTAyLTQ3N2YtYTMxOC05NjExYzVkMmQ4YzciLCJhdWQiOiI3ZDQ5ZWM3Mi0yOWNiLTQ0MTctOWIwOS02MjYwZGNiNjI0MGUifQ","protected":"eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCIsImtpZCI6IjEifQ","signature":"wsK5r0-AYdkmnZo70q5kaqvAuQUr5CNEvOZpGP6kJD1wX8Y27MUTkeMopBw5rMIgcxVLuoHVNi8XJoxMXqsiDQ"}"' }
      def test_parse
        # expect(client).to receive(:post).with("/v1/apps/#{jwt.id}/devices/#{device}/pre_keys", anything).and_return(post_resp)
        m = SelfSDK::Messages::Chat.new(messaging)
        c = m.parse(input)

        assert_equal input, c.input
        assert_equal "a", c.id
        assert_equal "b", c.from
        assert_equal "c", c.to
        assert_equal "d", c.audience
        assert_equal "e", c.expires
      end
    end


  end
end