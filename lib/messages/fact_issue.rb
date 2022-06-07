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

      def populate(selfid, facts, opts)
        @id = opts.fetch(:cid, SecureRandom.uuid)
        @exp_timeout = opts.fetch(:exp_timeout, DEFAULT_EXP_TIMEOUT)
        @viewers = opts.fetch(:viewers, nil)

        @from = @jwt.id
        @to = selfid
        @attestations = build_attestations!(facts)
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
          attestations: @attestations
        }
        # viewers
        b[:viewers] = @viewers unless @viewers.nil?
        b
      end

      protected

      def proto(to_device)
        @to_device = to_device
        recipient = "#{@to}:#{@to_device}"
        ciphertext = encrypt_message(@jwt.prepare(body), [{id: @to, device_id: @to_device}])

        m = SelfMsg::Message.new
        m.id = @id
        m.sender = "#{@jwt.id}:#{@messaging.device_id}"
        m.recipient = recipient
        m.ciphertext = ciphertext
        m
      end

      private

      def build_attestations!(facts)
        raise 'facts must be provided in the form of an array' unless facts.kind_of?(Array)

        attestations = []
        facts.each do |fact|
          att = fact.transform_keys(&:to_sym)
          raise 'invalid attestation : does not provide a key' if !att.has_key?(:key) || att[:key].empty?

          raise 'invalid attestation : does not provide a value' if !att.has_key?(:value) || att[:value].empty?
          att.delete(:source)

          attestations << sign(fact[:source], att)
        end

        attestations
      end

      def sign(source, facts)
        fact = { jti: SecureRandom.uuid,
                 sub: @to,
                 iss: @from,
                 iat: SelfSDK::Time.now.strftime('%FT%TZ'),
                 source: source,
                 verified: true,
                 facts: [ facts ] }
        @client.jwt.signed(fact)
      end
    end
  end
end
