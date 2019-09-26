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
        devices = @client.devices(@from)
        @messaging.share_information(@from, devices.first[:id], {
          typ: 'identity_info_resp',
          isi: @to,
          sub: @from,
          iat: Time.now.utc.strftime('%FT%TZ'),
          exp: (Time.now.utc + 3600).strftime('%FT%TZ'),
          jti: SecureRandom.uuid,
          fields: facts })
      end

    end
  end
end
