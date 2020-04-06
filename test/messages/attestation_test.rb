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
    subject{ Selfid::Messages::Attestation.new(messaging) }

    describe "parse" do
      let(:iss) { "issuer_id" }
      let(:sub) { "sub_id" }
      let(:aud) { "aud" }
      let(:source) { "source" }
      let(:expected_value) { "expected" }
      let(:operator) { "==" }
      let(:pkey) { "pkey" }
      let(:val) { "val" }
      let(:fact_name) {"fact_name"}
      let(:payload) { { iss: iss, sub:sub, aud:aud, source:source, expected_value: expected_value, operator: operator, fact_name: val }.to_json }
      let(:attestation) { { payload: "encrypted_payload" } }
      def test_parse
        expect(jwt).to receive(:decode).with('encrypted_payload').and_return(payload).once
        expect(jwt).to receive(:verify).with(attestation, pkey).and_return(true ).once
        expect(client).to receive(:public_keys).with(iss).and_return([{key: pkey}]).once

        subject.parse(fact_name.to_sym, attestation)

        assert_equal iss, subject.origin
        assert_equal sub, subject.to
        assert_equal aud, subject.audience
        assert_equal source, subject.source
        assert_equal expected_value, subject.expected_value
        assert_equal operator, subject.operator
        assert_equal "fact_name", subject.fact_name
        assert_equal source, subject.source
        assert_equal val, subject.value
      end
    end
  end
end