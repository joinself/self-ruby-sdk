# frozen_string_literal: true

module Selfid
  module Messages
    class Fact
      attr_accessor :name, :attestations, :operator, :result

      def initialize(messaging)
        @messaging = messaging
      end

      def parse(input, from)
        fact = JSON.parse(input, symbolize_names: true)

        @name = fact[:fact]
        @result = fact[:result]
        @operator = fact[:operator]
        @attestations = []

        fact[:attestations].each do |a|
          attestation = Selfid::Messages::Attestation.new(@messaging)
          attestation.parse(fact[:name].to_sym, a, from)
          @attestations.push(attestation)
        end
      end

      def value
        values = @attestations.collect{|a| a.value }.uniq
        raise StandardError("fact attestation values do not match") unless values.length > 1
        values.first
      end

    end
  end
end
