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
      let(:pkey) { "pkey" }
      let(:payload) { { iss: iss, sub:"", aud:"", source:"", expected_value: "", operator: "" }.to_json }
      let(:attestation) { { payload: "encrypted_payload" } }
      def test_parse
        expect(jwt).to receive(:decode).with('encrypted_payload').and_return(payload).once
        expect(jwt).to receive(:verify).with(attestation, pkey).and_return(true ).once
        expect(client).to receive(:public_keys).with(iss).and_return([{key: pkey}]).once
        subject.parse("fact_name", attestation)

      end
    end
  end
end