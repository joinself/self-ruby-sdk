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
        @id = payload[:jti]
        @from = payload[:iss]
        @to = payload[:sub]
        @expires = payload[:exp]
        @fields = payload[:fields]
        @status = payload[:status]
        @facts = {}
        payload[:facts] = {} if payload[:facts].nil?
        payload[:facts].each do |k, v|
          begin
            @facts[k] = Selfid::Messages::Fact.new(@messaging)
            @facts[k].parse(k, v, from)
          rescue StandardError => e
            Selfid.logger.info e.message
          end
        end
      end

      protected

        def proto
          Msgproto::Message.new(
            type: Msgproto::MsgType::MSG,
            id: SecureRandom.uuid,
            sender: "#{@jwt.id}:#{@messaging.device_id}",
            recipient: "#{@to}:#{@to_device}",
            ciphertext: @jwt.prepare({
                typ: MSG_TYPE,
                iss: @jwt.id,
                sub: @to,
                iat: Selfid::Time.now.strftime('%FT%TZ'),
                exp: (Selfid::Time.now + 3600).strftime('%FT%TZ'),
                jti: @id,
                status: @status,
                fields: @fields,
                facts: @facts,
              }),
          )
        end
    end
  end
end
