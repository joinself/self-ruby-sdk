require 'time'
require 'net/ntp'

module Selfid
  class Time
    @@last_check = nil
    def self.now
      seconds_to_expire = 60

      return ::Time.now.utc if ENV["RAKE_ENV"] == "test"
      if @diff.nil?
        Net::NTP.get("time.google.com")
        @@last_check = ::Time.parse(Net::NTP.get.time.to_s).utc
        @diff = (@@last_check - ::Time.now.utc).abs
        @now = (::Time.now + @diff).utc
        return @now
      end
      @now = (::Time.now + @diff).utc
      if @@last_check+seconds_to_expire < @now
        Net::NTP.get("time.google.com")
        @@last_check = ::Time.parse(Net::NTP.get.time.to_s).utc
        @diff = (@@last_check - ::Time.now.utc).abs
      end
      return @now
    end
  end
end
