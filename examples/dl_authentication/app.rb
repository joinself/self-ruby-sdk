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

# Register an observer for an authentication response
@app.authentication.subscribe do |auth|
  # The user has rejected the authentication
  if not auth.accepted?
    puts "Authentication request has been rejected"
    exit!
  end

  puts "User is now authenticated 🤘"
  exit
end

# Generate a DL code to authenticate
url = @app.authentication.generate_deep_link("https://my.test.com")
p "Authenticate with selfid through #{url}"

# Wait for some time
sleep 100