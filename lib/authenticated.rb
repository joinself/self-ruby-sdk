module Selfid
  class Authenticated
    attr_accessor :payload, :uuid, :selfid, :status

    def accepted?
      return false if payload.nil?

      payload[:status] == "accepted"
    end
  end
end
