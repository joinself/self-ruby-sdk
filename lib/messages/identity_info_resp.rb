require_relative 'base'

module Selfid
  module Messages
    class IdentityInfoResp < Base
      MSG_TYPE = "identity_info_resp"

      attr_accessor :facts

      def parse(input)
        @payload = get_payload input
        @id = payload[:jti]
        @from = payload[:isi]
        @to = payload[:sub]
        @expires = payload[:exp]
        @fields = payload[:fields]
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
                isi: @from,
                sub: @to,
                iat: Time.now.utc.strftime('%FT%TZ'),
                exp: (Time.now.utc + 3600).strftime('%FT%TZ'),
                jti: @id,
                fields: @fields,
                fields: @facts,
              }),
          )
        end
    end
  end
end
