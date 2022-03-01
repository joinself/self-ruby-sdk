# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'self_msgproto'
require_relative 'base'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class DocumentSignResponse < Base
      MSG_TYPE = "document.sign.resp"
      DEFAULT_EXP_TIMEOUT = 900

      attr_accessor :objects, :signed_objects

      def initialize(messaging)
        @typ = MSG_TYPE
        super
      end

      def parse(input, envelope)
        @input = input
        @typ = SelfSDK::Messages::DocumentSignResponse::MSG_TYPE
        @payload = get_payload(input)
        @id = payload[:cid]
        @from = payload[:iss]
        @to = payload[:sub]
        @expires = ::Time.parse(payload[:exp])
        @issued = ::Time.parse(payload[:iat])
        @audience = payload[:aud]
        @status = payload[:status]
        @objects = payload[:objects]
        @signed_objects = payload[:signed_objects]
      end

      protected

      def proto(to_device)
        nil
      end
    end
  end
end
