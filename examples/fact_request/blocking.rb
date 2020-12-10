# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'selfsdk'

# Process input data
abort("provide self_id to request information to") if ARGV.length != 1
user = ARGV.first
SelfSDK.logger = ::Logger.new($stdout).tap do |log|
  log.progname = "SelfSDK examples"
end if ENV.has_key?'LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}
opts[:storage_dir] = "#{File.expand_path("..", File.dirname(__FILE__))}/.self_storage"

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], ENV["STORAGE_KEY"], opts)

begin
  # Request display_name and email_address to the specified user
  res = @app.facts.request(user, [SelfSDK::FACT_DISPLAY_NAME, SelfSDK::FACT_EMAIL])

  # Information request has been rejected by the user
  if res.status == "rejected"
    puts 'Information request rejected'
    exit!
  end

  # Response comes in form of facts easy to access with facts method
  puts "Hello #{res.fact(SelfSDK::FACT_DISPLAY_NAME).attestations.first.value}"
rescue => e
  puts "ERROR : #{e}"
  exit!
end
