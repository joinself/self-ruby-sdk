# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'self_msgproto'
require_relative 'base'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class FactRequest < Base
      MSG_TYPE = "identities.facts.query.req"
      DEFAULT_EXP_TIMEOUT = 900

      attr_accessor :facts, :options

      def parse_facts(facts)
        @facts = []
        facts.each do |fact|
          f = SelfSDK::Messages::Fact.new(@messaging)
          f.parse(fact)
          @facts << f.to_hash
        end
        @facts
      end

      def populate(selfid, facts, opts)
        @id = SecureRandom.uuid
        @from = @client.jwt.id
        @to = selfid
        @facts = parse_facts(facts)

        @id = opts[:cid] if opts.include?(:cid)
        @options = opts.fetch(:options, false)
        @description = opts.include?(:description) ? opts[:description] : nil
        @exp_timeout = opts.fetch(:exp_timeout, DEFAULT_EXP_TIMEOUT)

        @intermediary = if opts.include?(:intermediary)
                          opts[:intermediary]
                        end
      end

      def parse(input, envelope=nil)
        @input = input
        @typ = MSG_TYPE
        @payload = get_payload input
        @id = @payload[:cid]
        @from = @payload[:iss]
        @to = @payload[:sub]
        @audience = payload[:aud]
        @expires = @payload[:exp]
        @description = @payload.include?(:description) ? @payload[:description] : nil
        @facts = @payload[:facts]
        @options = @payload[:options]

        if envelope
          issuer = envelope.sender.split(":")
          @from_device = issuer.last
        end
      end

      def build_response
        m = SelfSDK::Messages::FactResponse.new(@messaging)
        m.id = @id
        m.from = @to
        m.to = @from
        m.sub = @to
        m.audience = @from
        m.facts = @facts
        m
      end

      def share_facts(facts)
        m = build_response
        m.facts = parse_facts(facts)
        m.send_message
      end

      def body
        b = {
          typ: MSG_TYPE,
          iss: @jwt.id,
          sub: @to,
          iat: SelfSDK::Time.now.strftime('%FT%TZ'),
          exp: (SelfSDK::Time.now + @exp_timeout).strftime('%FT%TZ'),
          cid: @id,
          jti: SecureRandom.uuid,
          facts: @facts,
        }
        b[:options] = @options unless (@options.nil? || @options == false)
        b[:description] = @description unless (@description.nil? || @description.empty?)
        b
      end

      protected

      def proto(to_device)
        @to_device = to_device
        if @intermediary.nil?
          recipient = "#{@to}:#{@to_device}"
          ciphertext = encrypt_message(@jwt.prepare(body), [{id: @to, device_id: @to_device}])
        else
          recipient = "#{@intermediary}:#{@to_device}"
          ciphertext = encrypt_message(@jwt.prepare(body), [{id: @intermediary, device_id: @to_device}])
        end

        m = SelfMsg::Message.new
        m.id = @id
        m.sender = "#{@jwt.id}:#{@messaging.device_id}"
        m.recipient = recipient
        m.ciphertext = ciphertext
        m
      end
    end
  end
end
