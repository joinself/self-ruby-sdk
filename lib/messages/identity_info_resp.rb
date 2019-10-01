require_relative 'base'
require_relative 'fact'
require_relative '../time'

module Selfid
  module Messages
    class IdentityInfoResp < Base
      MSG_TYPE = "identity_info_resp"

      attr_accessor :facts

      def parse(input)
        @payload = get_payload input
        @id = payload[:jti]
        @from = payload[:iss]
        @to = payload[:sub]
        @expires = payload[:exp]
        @fields = payload[:fields]
        @facts = {}
        payload[:facts].each do |k, v|
          begin
            @facts[k] = Selfid::Messages::Fact.new(k, v, from, @messaging)
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
            sender: "#{@from}:#{@messaging.device_id}",
            recipient: "#{@to}:#{@to_device}",
            ciphertext: @jwt.prepare_encoded({
                typ: MSG_TYPE,
                iss: @from,
                sub: @to,
                iat: Selfid::Time.now.strftime('%FT%TZ'),
                exp: (Selfid::Time.now + 3600).strftime('%FT%TZ'),
                jti: @id,
                fields: @fields,
                facts: @facts,
              }),
          )
        end
    end
  end
end
