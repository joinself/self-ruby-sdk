require_relative 'base'
require_relative '../ntptime'

module Selfid
  module Messages
    class IdentityInfoReq < Base
      MSG_TYPE = "identity_info_req"
      attr_accessor :proxy, :assertions

      def parse(input)
        @input = input
        @payload = get_payload input
        @id = @payload[:jti]
        @from = @payload[:iss]
        @to = @payload[:sub]
        @expires = @payload[:exp]
        @fields = @payload[:fields]
        @proxy = @payload[:proxy] if @payload.include? :proxy
        @assertions = @payload[:assertions]
        @type = MSG_TYPE
      end

      def share_facts(facts)
        m = Selfid::Messages::IdentityInfoResp.new(@messaging)
        m.id = @id
        m.from = @to
        m.to = @from
        m.to_device = @messaging.device_id
        m.fields = @fields
        m.facts = facts

        m.send
      end

      protected

        def proto
          recipient = "#{@to}:#{@to_device}"
          recipient = @proxy unless @proxy.nil?
          Msgproto::Message.new(
            type: Msgproto::MsgType::MSG,
            id: @id,
            sender: "#{@jwt.id}:#{@messaging.device_id}",
            recipient: recipient,
            ciphertext: @jwt.prepare_encoded({
              typ: MSG_TYPE,
              iss: @jwt.id,
              sub: @to,
              iat: Selfid::Time.now.strftime('%FT%TZ'),
              exp: (Selfid::Time.now + 3600).strftime('%FT%TZ'),
              jti: @id,
              fields: @fields,
            }),
          )
        end
    end
  end
end
