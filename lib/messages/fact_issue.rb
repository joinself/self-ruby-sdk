# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'self_msgproto'
require_relative 'base'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class FactIssue < Base
      MSG_TYPE = "identities.facts.issue"
      DEFAULT_EXP_TIMEOUT = 900

      def initialize(messaging)
        @typ = MSG_TYPE
        super
      end

      def populate(selfid, source, facts, opts)
        @attestations = build_attestations!(facts)

        @id = opts.fetch(:cid, SecureRandom.uuid)
        @exp_timeout = opts.fetch(:exp_timeout, DEFAULT_EXP_TIMEOUT)
        @source = source
        @viewers = opts.fetch(:viewers, "")

        @from = @client.jwt.id
        @to = selfid
      end

      def body
        b = {
          typ: MSG_TYPE,
          iss: @jwt.id,
          aud: @to,
          sub: @to,
          iat: SelfSDK::Time.now.strftime('%FT%TZ'),
          exp: (SelfSDK::Time.now + @exp_timeout).strftime('%FT%TZ'),
          cid: @id,
          jti: SecureRandom.uuid,
          status: 'verified',
          viewers: @viewers,
          attestations: @attestations
        }
        # viewers
        b[:viewers] = @viewers unless @viewers.empty?
        puts b.to_json
        b
      end

      private

      def build_attestations!(facts)
        raise 'facts must be provided in the form of an array' unless facts.kind_of?(Array)

        attestations = []
        facts.each do |fact|
          att = fact.transform_keys(&:to_sym)
          raise 'invalid attestation : does not provide a key' if !att.has_key?(:key) || att[:key].empty?

          raise 'invalid attestation : does not provide a key' if !att.has_key?(:value) || att[:value].empty?

          attestations << sign(att)
        end

        attestations
      end

      def sign(facts)
        fact = { jti: SecureRandom.uuid,
                 sub: @to,
                 iss: @origin,
                 iat: SelfSDK::Time.now.strftime('%FT%TZ'),
                 source: @source,
                 verified: true,
                 facts: facts }
        @messaging.jwt.signed(fact)
      end
    end
  end
end
