require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfid'

require 'webmock/minitest'

class SelfidTest < Minitest::Test
  describe 'Selfid::Messages::Attestation' do
    let(:client) { double("client") }
    let(:jwt) { double("jwt") }
    let(:messaging) do
      double("messaging", jwt: jwt, client: client)
    end
    subject{ Selfid::Messages::Fact.new(messaging) }

    describe "parse" do
      let(:iss) { "issuer_id" }
      let(:pkey) { "pkey" }
      let(:operator) { "pkey" }
      let(:payload) { { iss: iss, sub:"", aud:"", source:"", expected_value: "", operator: "" }.to_json }
      let(:attestation) { { payload: "encrypted_payload" } }
      let(:fact) { { fact: "fact_name", operator: "==", attestations: [ attestation ], expected_value: "lol" } }
      def test_parse
        expect(jwt).to receive(:decode).with('encrypted_payload').and_return(payload).once
        expect(jwt).to receive(:verify).with(attestation, pkey).and_return(true ).once
        expect(client).to receive(:public_keys).with(iss).and_return([{key: pkey}]).once

        subject.parse(fact)
        parsed_fact = subject.to_hash

            assert_equal "fact_name", parsed_fact[:fact]
        assert_equal "==", parsed_fact[:operator]
        assert_equal 1, parsed_fact[:attestations].length
        assert_equal "lol", parsed_fact[:expected_value]
      end
    end
  end
end