# frozen_string_literal: true

require_relative 'attestation'

module Selfid
  module Messages
    class Fact
      attr_accessor :name, :attestations, :operator, :expected_value, :sources

      def initialize(messaging)
        @messaging = messaging
      end

      def parse(fact)
        @name = Selfid::fact_name(fact[:fact])

        @operator = ""
        @operator = Selfid::operator(fact[:operator]) if fact[:operator]

        @sources = []
        fact[:sources]&.each do |s|
          @sources << Selfid::source(s)
        end

        @expected_value = fact[:expected_value] || ""
        @attestations = []

        fact[:attestations]&.each do |a|
            attestation = Selfid::Messages::Attestation.new(@messaging)
            attestation.parse(fact[:fact].to_sym, a)
            @attestations.push(attestation)
          end
      end

      def validate!(original)
        @attestations.each do |a|
          a.validate! original
        end
      end

      def to_hash
        h = { fact: @name }
        unless @sources.nil?
          h[:sources] = @sources if @sources.length > 0
        end
        h[:operator] = @operator unless @operator.empty?
        unless @attestations.nil?
          h[:attestations] = @attestations if @attestations.length > 0
        end
        h[:expected_value] = @expected_value unless @expected_value.empty?
        h
      end
    end
  end
end
