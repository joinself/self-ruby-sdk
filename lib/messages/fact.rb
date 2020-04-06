# frozen_string_literal: true

require_relative 'attestation'

module Selfid
  module Messages
    class Fact
      attr_accessor :name, :attestations, :operator, :expected_value

      def initialize(messaging)
        @messaging = messaging
      end

      def parse(fact)
        @name = fact[:fact]
        @operator = fact[:operator] || ""
        @expected_value = fact[:expected_value] || ""
        @attestations = []

        fact[:attestations].each do |a|
          attestation = Selfid::Messages::Attestation.new(@messaging)
          attestation.parse(fact[:fact].to_sym, a)
          @attestations.push(attestation)
        end
      end

      def to_hash
        {
          fact: @name,
          operator: @operator,
          attestations: @attestations,
          expected_value: @expected_value,
        }
      end
    end
  end
end
