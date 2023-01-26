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

  puts "Setting up app #{ENV["SELF_APP_ID"]}"
  # Connect your app to Self network, get your connection details creating a new
  # app on https://developer.selfsdk.net/
  app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_DEVICE_SECRET"], ENV["STORAGE_KEY"], storage_dir, opts)

  app.messaging.permit_connection("*")
  app
end
