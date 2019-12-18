module Selfid
  class Authenticated
    attr_accessor :payload, :uuid, :selfid, :status

    def initialize(payload)
      return if payload.nil?

      @payload = payload
      @uuid = payload[:cid]
      @selfid = payload[:sub]
    end

    def accepted?
      return false if @payload.nil?

      @payload[:status] == "accepted"
    end

    def to_hash
      { uuid: @uuid,
        selfid: @selfid,
        accepted: accepted? }
    end

  end
end
