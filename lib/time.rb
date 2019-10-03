require 'time'
require 'net/ntp'

module Selfid
  class Time
    def self.now
      return ::Time.now.utc if ENV["RAKE_ENV"] == "test"
      if @time.nil?
        Net::NTP.get("time.google.com")
        @time = ::Time.parse(Net::NTP.get.time.to_s).utc
      end
      return @time
    end
  end
end
