# frozen_string_literal: true

require 'selfid'

# Process input data
abort("provide self_id to authenticate") if ARGV.length != 1
user = ARGV.first
Selfid.logger = Logger.new('/dev/null') if ENV.has_key?'NO_LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], ENV["STORAGE_KEY"], opts)

# Authenticate a user to your app.
puts "Sending an authentication request to your device..."
begin
  auth = @app.authentication.request user
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