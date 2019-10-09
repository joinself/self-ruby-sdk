require 'time'
require 'net/ntp'

module Selfid
  class Time
    def self.now
      return ::Time.now.utc if ENV["RAKE_ENV"] == "test"
      if @diff.nil?
        Net::NTP.get("time.google.com")
        @last_check = ::Time.parse(Net::NTP.get.time.to_s).utc
        @diff = (@last_check - ::Time.now.utc).abs
      end
      @now = (::Time.now + @diff).utc
      if @last_check + 3600 > @now
        Net::NTP.get("time.google.com")
        @last_check = ::Time.parse(Net::NTP.get.time.to_s).utc
        @diff = (@last_check - ::Time.now.utc).abs
      end
      return @now
    end
  end
end
