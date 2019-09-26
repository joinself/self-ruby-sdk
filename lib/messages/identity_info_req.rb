require_relative 'base'

module Selfid
  module Messages
    class IdentityInfoReq < Base
      def parse(input)
        @payload = get_payload input
        @id = @payload[:jti]
        @from = @payload[:isi]
        @to = @payload[:sub]
        @expires = @payload[:exp]
        @fields = @payload[:fields]
      end

      def share_facts(facts)
        # TODO (adriacidre) : properly get this stuff from the jwt
        @from_device = "1"
        m = Selfid::Messages::IdentityInfoResp.new(@client, @jwt, @messaging)
        m.from = @to
        m.to = @from
        m.to_device = @from_device
        m.fields = @fields
        m.facts = facts

        m.send_async
      end

      protected

        def proto
          # TODO (adriacidre) : get this stuff configured somwhow
          @device_id = "1"
          Msgproto::Message.new(
            type: Msgproto::MsgType::MSG,
            id: @id,
            sender: "#{@jwt.id}:#{@device_id}",
            recipient: "#{to}:#{to_device}",
            ciphertext: @jwt.prepare_encoded({
                typ: 'identity_info_req',
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
