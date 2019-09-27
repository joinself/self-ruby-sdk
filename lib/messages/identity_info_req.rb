require_relative 'base'

module Selfid
  module Messages
    class IdentityInfoReq < Base
      MSG_TYPE = "identity_info_req"

      def parse(input)
        @payload = get_payload input
        @id = @payload[:jti]
        @from = @payload[:isi]
        @to = @payload[:sub]
        @expires = @payload[:exp]
        @fields = @payload[:fields]
      end

      def share_facts(facts)
        m = Selfid::Messages::IdentityInfoResp.new(@messaging)
        m.from = @to
        m.to = @from
        m.to_device = @messaging.device_id
        m.fields = @fields
        m.facts = facts

        m.send_async
      end

      protected

        def proto
          Msgproto::Message.new(
            type: Msgproto::MsgType::MSG,
            id: @id,
            sender: "#{@jwt.id}:#{@messaging.device_id}",
            recipient: "#{@to}:#{@to_device}",
            ciphertext: @jwt.prepare_encoded({
                typ: MSG_TYPE,
                isi: @jwt.id,
                sub: @to,
                iat: Time.now.utc.strftime('%FT%TZ'),
                exp: (Time.now.utc + 3600).strftime('%FT%TZ'),
                jti: @id,
                fields: @fields,
              }),
          )
        end
    end
  end
end
