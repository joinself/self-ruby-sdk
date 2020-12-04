# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'time'
require 'net/ntp'

module SelfSDK
  class Time
    @@last_check = nil
    @diff = nil
    def self.now
      timeout = 1
      ntp_time = nil
      5.times do
        begin
          ntp_time = get_ntp_current_time
          break
        rescue Timeout::Error
          puts "time.google.com timed out, retrying in #{timeout} seconds..."
          sleep timeout
          timeout = timeout+1
        end
      end
      raise Timeout::Error.new("ntp sync timed out") if ntp_time.nil?
      ntp_time
    end

    private

    def self.get_ntp_current_time
      seconds_to_expire = 60

      return ::Time.now.utc if ENV["RAKE_ENV"] == "test"

      if @diff.nil?
        self.sync
        return @now
      end
      @now = (::Time.now + @diff).utc
      if @@last_check + seconds_to_expire < @now
        self.sync
      end
      @now
    end

    def self.sync
      @@last_check = ::Time.parse(Net::NTP.get("time.google.com", "ntp", 2).time.to_s).utc
      @diff = (@@last_check - ::Time.now.utc).abs
      @now = (::Time.now + @diff).utc
    end
  end
end
