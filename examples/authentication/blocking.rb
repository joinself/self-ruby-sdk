# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'selfsdk'

# Process input data
abort("provide self_id to authenticate") if ARGV.length != 1
user = ARGV.first
SelfSDK.logger = ::Logger.new($stdout).tap do |log|
  log.progname = "SelfSDK examples"
end if ENV.has_key?'LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}
storage_dir = "#{File.expand_path("..", File.dirname(__FILE__))}/self_storage"

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], ENV["STORAGE_KEY"], storage_dir, opts)

# Authenticate a user to your app.
puts "Sending an authentication request to your device..."
begin
  auth = @app.authentication.request user
  if auth.nil?
    puts "Authentication timed out"
    exit!
  end

  # The user has rejected the authentication
  if not auth.accepted?
    puts "Authentication request has been rejected"
    exit!
  end

  puts "User is now authenticated 🤘"
  exit!
rescue => e
  puts "ERROR : #{e}"
  exit!
end