# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'self_msgproto'
require_relative 'base'
require_relative '../ntptime'

module SelfSDK
  module Messages
    class ConnectionResponse < Base
      MSG_TYPE = "identities.connections.resp"
      DEFAULT_EXP_TIMEOUT = 900

      attr_accessor :facts, :options, :auth

      def initialize(messaging)
        @typ = MSG_TYPE
        super
      end

      def populate(selfid)
        @id = SecureRandom.uuid
        @from = @client.jwt.id
        @to = selfid
      end

      def parse(input, envelope=nil)
        @typ = MSG_TYPE
        @payload = get_payload input
        @body = @payload[:msg]
        @status = @payload[:status]
      end

      def get_payload(input)
        body = if input.is_a? String
                 input
               else
                 input.ciphertext
               end

        jwt = JSON.parse(body, symbolize_names: true)
        payload = JSON.parse(@jwt.decode(jwt[:payload]), symbolize_names: true)
        header = JSON.parse(@jwt.decode(jwt[:protected]), symbolize_names: true)
        @from = payload[:iss]
        verify! jwt, header[:kid]
        payload
      end

    end
  end
end
