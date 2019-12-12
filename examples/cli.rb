# frozen_string_literal: true

require_relative '../lib/selfid.rb'
user = "23799253795"

# Selfid.logger = Logger.new('/dev/null')

@app = Selfid::App.new(
  ENV["APP_ID"],
  ENV["APP_KEY"],
  self_url: ENV["SELF_URL"],
  messaging_url: ENV["SELF_MESSAGING_URL"]
)

@app.connect("*")

puts "Sending an authentication request to your device..."
res = @app.authenticate(user)

if !res[:accepted]
  puts "Authentication request has been rejected"
  return
end

puts "You are now authenticated 🤘"
puts ""
puts "Requesting basic information"

res = @app.request_information(user, [
  {
    source: "user-defined",
    field: "name",
  },
  {
    source: "user-defined",
    field: "email",
  }
  ], type: :sync)

if res.nil?
  puts 'An undetermined problem happened with your request, try again in a few minutes'
  return
end
if res.status == "rejected"
  puts 'Information request rejected'
  return
end

puts "Hello #{res.facts[:name].value}"
