# frozen_string_literal: true

require_relative 'base'
require_relative 'fact'
require_relative '../ntptime'

module Selfid
  module Messages
    class IdentityInfoResp < Base
      MSG_TYPE = "identity_info_resp"

      attr_accessor :facts

      def parse(input)
        @input = input
        @typ = MSG_TYPE
        @payload = get_payload input
        @id = payload[:cid]
        @from = payload[:iss]
        @to = payload[:sub]
        @expires = payload[:exp]
        @status = payload[:status]
        @facts = []
        payload[:facts] = [] if payload[:facts].nil?
        payload[:facts].each do |f|
          begin
            fact = Selfid::Messages::Fact.new(@messaging)
            fact.parse(f)
            @facts.push(fact)
          rescue StandardError => e
            Selfid.logger.info e.message
          end
        end
      end

      def fact(name)
        @facts.select{|f| f.name == name}.first
      end

      protected

      def proto
        encoded_facts = []
        @facts.each do |fact|
          encoded_facts.push(fact.to_hash)
        end
        body = @jwt.prepare(
          typ: MSG_TYPE,
          iss: @jwt.id,
          sub: @to,
          iat: Selfid::Time.now.strftime('%FT%TZ'),
          exp: (Selfid::Time.now + 3600).strftime('%FT%TZ'),
          cid: @id,
          jti: SecureRandom.uuid,
          status: @status,
          facts: encoded_facts,
        )

        Msgproto::Message.new(
          type: Msgproto::MsgType::MSG,
          id: SecureRandom.uuid,
          sender: "#{@jwt.id}:#{@messaging.device_id}",
          recipient: "#{@to}:#{@to_device}",
          ciphertext: body,
        )
      end
    end
  end
end
