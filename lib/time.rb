require 'net/ntp'

module Selfid
  class Time
    def self.now
      return ::Time.now.utc
      # Net::NTP.get("time.google.com")
      # return ::Time.parse(Net::NTP.get.time.to_s).utc
    end
  end
end
