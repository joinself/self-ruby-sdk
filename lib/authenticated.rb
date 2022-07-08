# Copyright 2020 Self Group Ltd. All Rights Reserved.

module SelfSDK
  class Authenticated
    attr_accessor :payload, :uuid, :selfsdk, :status

    def initialize(payload)
      return if payload.nil?

      @payload = payload
      @uuid = payload[:cid]
      @selfsdk = payload[:sub]
    end

    def accepted?
      return false if @payload.nil?
      return false if @payload[:auth] != true

      @payload[:status] == "accepted"
    end

    def to_hash
      { uuid: @uuid,
        selfsdk: @selfsdk,
        accepted: accepted? }
    end

  end
end
