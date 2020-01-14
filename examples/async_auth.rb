# frozen_string_literal: true

require_relative '../lib/selfid.rb'
user = "57340034173"

# Disable the debug logs
Selfid.logger = Logger.new('/dev/null')

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"])

# Allows connections from everyone on self network to your app.
@app.connect("*")

# Authenticate a user to our app.
puts "Sending an authentication request to your device..."
@app.authenticate user do |auth|
  if !auth.accepted?
    puts "Authentication request has been rejected"
    exit!
  end

  puts "You are now authenticated 🤘"
  puts ""
  exit!
end

sleep 10
