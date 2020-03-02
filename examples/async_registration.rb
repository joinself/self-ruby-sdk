# frozen_string_literal: true

require_relative '../lib/selfid.rb'
user = "47347840589"

# Disable the debug logs
# Selfid.logger = Logger.new('/dev/null')

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], 
                       ENV["SELF_APP_SECRET"],
                       base_url: "https://api.review.selfid.net",
                       messaging_url: "wss://messaging.review.selfid.net/v1/messaging")
# Allows connections from everyone on self network to your app.
@app.permit_connection("*")

# Authenticate a user to our app.
puts "Sending an authentication request to your device..."
@app.authenticate user do |auth|
  if not auth.accepted?
    puts "Authentication request has been rejected"
    exit!
  end

  puts "You are now authenticated 🤘"
  puts ""
  puts "Requesting basic information"

  @app.request_information(user, [{fact:'display_name'}, {fact:'email_address'}]) do |res|
    if res.nil?
      puts 'An undetermined problem happened with your request, try again in a few minutes'
      exit!
    end
    if res.status == "rejected"
      puts 'Information request rejected'
      exit!
    end

    puts "Hello #{res.fact('display_name').value}"
    exit!
  end
end

sleep 100
