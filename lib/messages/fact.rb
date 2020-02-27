# frozen_string_literal: true

module Selfid
  module Messages
    class Fact
      attr_accessor :name, :attestations, :operator, :result

      def initialize(messaging)
        @messaging = messaging
      end

      def parse(fact)
        @name = fact[:fact]
        @result = fact[:result]
        @operator = fact[:operator]
        @attestations = []

        fact[:attestations].each do |a|
          attestation = Selfid::Messages::Attestation.new(@messaging)
          attestation.parse(fact[:fact].to_sym, a)
          @attestations.push(attestation)
        end
      end

      def value
        values = @attestations.collect{|a| a.value }.uniq
        raise StandardError("fact attestation values do not match") if values.length > 1
        values.first
      end

    end
  end
end
