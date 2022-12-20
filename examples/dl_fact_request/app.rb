# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'selfsdk'

# Enable the debug logs
SelfSDK.logger = ::Logger.new($stdout).tap do |log|
  log.progname = "SelfSDK examples"
end if ENV.has_key?'LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}
storage_dir = "#{File.expand_path("..", File.dirname(__FILE__))}/self_storage"

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_DEVICE_SECRET"], ENV["STORAGE_KEY"], storage_dir, opts)

# Register an observer for an information response
@app.messaging.subscribe :fact_response do |res|
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

# You can manage your redirection codes on your app management on the
# developer portal
redirection_code = "90d017d1"

# Generate a DL code for a fact request
url = @app.facts.generate_deep_link([:display_name], redirection_code)
p "Request display name through #{url}"

# Wait for some time
sleep 100
