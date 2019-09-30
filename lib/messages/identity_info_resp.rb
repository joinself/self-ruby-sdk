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
        @from = payload[:isi]
        @to = payload[:sub]
        @expires = payload[:exp]
        @fields = payload[:fields]
        @facts = {}
        payload[:facts].each do |k, v|
          @facts[k] = Selfid::Messages::Fact.new(k, v, @messaging)
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
                isi: @from,
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
