require_relative 'base'

module Selfid
  module Messages
    class IdentityInfoResp < Base
      def parse(input)
        @payload = get_payload input
        @id = payload[:jti]
        @from = payload[:isi]
        @to = payload[:sub]
        @expires = payload[:exp]
        @fields = payload[:fields]
      end
    end
  end
end
