# frozen_string_literal: true

require 'selfid'

# Disable the debug logs
Selfid.logger = Logger.new('/dev/null') if ENV.has_key?'NO_LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_BASE_URL') ? { base_url: ENV["SELF_BASE_URL"], messaging_url: ENV["SELF_MESSAGING_URL"] } : {}
opts = ENV.has_key?('SELF_ENV') ? { env: ENV['SELF_ENV'] } : {}

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], ENV["STORAGE_KEY"], opts)

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

# Generate a DL code to authenticate
url = @app.facts.generate_deep_link([:display_name], "https://my.test.com")
p "Authenticate with selfid through #{url}"

# Wait for some time
sleep 100
