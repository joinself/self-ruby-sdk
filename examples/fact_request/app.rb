# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'selfsdk'

# Process input data
abort("provide self_id to request information to") if ARGV.length != 1
user = ARGV.first
SelfSDK.logger = Logger.new('/dev/null') if ENV.has_key?'NO_LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}
opts[:storage_dir] = "#{File.expand_path("..", File.dirname(__FILE__))}/.self_storage"

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], ENV["STORAGE_KEY"], opts)

# Request display_name and email_address to the specified user
begin
  @app.facts.request(user, [:display_name, :email_address]) do |res|
    # Information request has been rejected by the user
    if res.status == "rejected"
      puts 'Information request rejected'
      exit!
    end

    # Response comes in form of facts easy to access with facts method
    attestations = res.attestation_values_for(:display_name).join(", ")
    puts "Hello #{attestations}!"
    exit!
  end
rescue => e
  puts "ERROR : #{e}"
  exit!
end

# Wait for asyncrhonous process to finish
sleep 100
