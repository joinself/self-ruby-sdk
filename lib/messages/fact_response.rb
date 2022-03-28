# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'base'
require_relative 'fact'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class FactResponse < Base
      MSG_TYPE = "identities.facts.query.resp"

      attr_accessor :facts, :audience

      def parse(input, envelope=nil)
        @input = input
        @typ = MSG_TYPE
        @payload = get_payload input
        @id = payload[:cid]
        @from = payload[:iss]
        @to = payload[:sub]
        @expires = ::Time.parse(payload[:exp])
        @issued = ::Time.parse(payload[:iat])
        @audience = payload[:aud]
        @status = payload[:status]
        @auth = payload[:auth]
        @facts = []
        payload[:facts] = [] if payload[:facts].nil?
        payload[:facts].each do |f|
          begin
            fact = SelfSDK::Messages::Fact.new(@messaging)
            fact.parse(f)
            @facts.push(fact)
          rescue StandardError => e
            SelfSDK.logger.info e.message
          end
        end
        if envelope
          issuer = envelope.sender.split(":")
          @from_device = issuer.last
        end
      end

      def fact(name)
        name = SelfSDK::fact_name(name)
        @facts.select{|f| f.name == name}.first
      end

      def attestations_for(name)
        f = fact(name)
        return [] if f.nil?
        f.attestations
      end

      def attestation_values_for(name)
        a = attestations_for(name)
        a.map{|a| a.value}
      end

      def validate!(original)
        super
        @facts.each do |f|
          f.validate! original
        end
      end

      def body
        encoded_facts = []
        @facts.each do |fact|
          encoded_facts.push(fact.to_hash)
        end

        { typ: MSG_TYPE,
          iss: @jwt.id,
          sub: @sub || @to,
          aud: @audience,
          iat: SelfSDK::Time.now.strftime('%FT%TZ'),
          exp: (SelfSDK::Time.now + 3600).strftime('%FT%TZ'),
          cid: @id,
          jti: SecureRandom.uuid,
          status: @status,
          facts: encoded_facts,
          auth: @auth }
      end

      protected

      def proto(to_device)
        @to_device = to_device
        Msgproto::Message.new(
          type: Msgproto::MsgType::MSG,
          id: SecureRandom.uuid,
          sender: "#{@jwt.id}:#{@messaging.device_id}",
          recipient: "#{@to}:#{@to_device}",
          ciphertext: encrypt_message(@jwt.prepare(body), [{id: @to, device_id: @to_device}])
        )
      end
    end
  end
end
