# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true
require_relative '../../lib/selfsdk'

def setup_sdk
  SelfSDK.logger = ::Logger.new($stdout).tap do |log|
    log.progname = "SelfSDK examples"
  end if ENV.has_key?'LOGS'

  # You can point to a different environment by passing optional values to the initializer
  opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}
  storage_dir = "#{File.expand_path("..", File.dirname(__FILE__))}/self_storage"

  # Connect your app to Self network, get your connection details creating a new
  # app on https://developer.selfsdk.net/
  app = SelfSDK::App.new(ENV["SELF_APP_ID"], 
                         ENV["SELF_APP_DEVICE_SECRET"], 
                         ENV["STORAGE_KEY"], 
                         storage_dir,
                         opts).start

  app.messaging.permit_connection("*")

  myapp = app.identity.get(ENV["SELF_APP_ID"])
  box = TTY::Box.frame(padding: 3, align: :left, title: {top_left: "#{myapp[:publisher][:name]}::#{myapp[:name]}"} ) do
    c = "\xE2\x9C\x94".green
    f = "\xE2\x9C\x87".red
    w = "\xE2\x9A\xA0".yellow
    errors = "Connection setup for app #{myapp[:publisher][:name]}::#{myapp[:name]} (#{ENV["SELF_APP_ID"]})\n\n"

    if myapp[:allows_messaging]
      errors += "#{c} Messaging enabled\n"
    else
      errors += "#{f} Messaging enabled\n"
    end

    if myapp[:allows_calls]
      errors += "#{c} Voice calls enabled\n"
    else
      errors += "#{f} Voice calls enabled\n"
    end

    if !myapp[:allows_messaging] || !myapp[:allows_calls]
      errors += "\nPlease consider fixing some of the configuration issues \nat the developer portal, some examples may fail\n"
    end
    errors += "\n\n#{w} Please make sure you're conntected to #{myapp[:publisher][:name]}::#{myapp[:name]} on your device"

    errors
  end
  print "\n" + box + "\n"

  puts ""

  app
end
