# frozen_string_literal: true

require 'selfid'

# Process input data
abort("provide self_id to authenticate") if ARGV.length != 1
user = ARGV.first
Selfid.logger = Logger.new('/dev/null') if ENV.has_key?'NO_LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_BASE_URL') ? { base_url: ENV["SELF_BASE_URL"], messaging_url: ENV["SELF_MESSAGING_URL"] } : {}

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], opts)

# Authenticate a user to your app.
puts "Sending an authentication request to your device..."
auth = @app.authentication.request user
# The user has rejected the authentication
if not auth.accepted?
  puts "Authentication request has been rejected"
  exit!
end

puts "User is now authenticated 🤘"
exit!
