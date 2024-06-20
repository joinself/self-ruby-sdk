# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative 'base'
require_relative 'fact'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class FactResponse < Base
      MSG_TYPE = "identities.facts.query.resp"

      attr_accessor :facts, :audience, :auth

      def initialize(messaging)
        @typ = MSG_TYPE
        super
      end

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
            if f[:fact] == 'photo'
              f[:fact] = :image_hash
            end
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
        name = @messaging.source.normalize_fact_name(name)
        name = "image_hash" if name == 'photo'
        @facts.select{|f| f.name == name}.first
      end


      # Returns an attestation by name
      #
      # @param name [String] the name of the fact to retrieve the attestation for
      # @return [Object, nil] the first attestation of the fact, or nil if no fact is found
      def attestation(name)
        f = fact(name)
        return nil if f.nil?

        f.attestations.first
      end

      def attestations_for(name)
        f = fact(name)
        return [] if f.nil?

        f.attestations
      end

      def attestation_values_for(name)
        aa = attestations_for(name)
        aa.map{|a| a.value}
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

      def auth_response?
        @auth == true
      end

      def object(hash)
        payload[:objects].each do |o|
          if o[:image_hash] == hash
            return SelfSDK::Chat::FileObject.new(
              @messaging.client.jwt.auth_token,
              @messaging.client.self_url).build_from_object(o)
          end
        end
      end
    end
  end
end
