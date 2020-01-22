# frozen_string_literal: true

require_relative '../lib/selfid.rb'
user = "23799253795"

# Disable the debug logs
Selfid.logger = Logger.new('/dev/null')

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"])

# Allows connections from everyone on self network to your app.
@app.acl_permit("*")

# Authenticate a user to our app.
puts "Sending an authentication request to your device..."
auth = @app.authenticate(user)

if not auth.accepted?
  puts "Authentication request has been rejected"
  exit!
end

puts "You are now authenticated 🤘"
puts ""
puts "Requesting basic information"

res = @app.request_information(user, ['name','email'])

if res.nil?
  puts 'An undetermined problem happened with your request, try again in a few minutes'
  return
end
if res.status == "rejected"
  puts 'Information request rejected'
  return
end

puts "Hello #{res.facts[:name].value}"
