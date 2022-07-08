# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'attestation'

module SelfSDK
  module Messages
    class Fact
      attr_accessor :name, :attestations, :operator, :expected_value, :sources

      def initialize(messaging)
        @messaging = messaging
      end

      def parse(fact)
        @name = @messaging.source.normalize_fact_name fact[:fact]
        @operator = @messaging.source.normalize_operator!(fact[:operator])
        @sources = []
        fact[:sources]&.each do |s|
          @sources << s.to_s
        end
        @issuers = []
        fact[:issuers]&.each do |i|
          @issuers << i.to_s
        end

        @expected_value = fact[:expected_value] || ""
        @attestations = []

        fact[:attestations]&.each do |a|
            attestation = SelfSDK::Messages::Attestation.new(@messaging)
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
        h[:issuers] = @issuers if @issuers.length > 0
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
