# frozen_string_literal: true

require 'selfid'

# Process input data
abort("provide self_id to request information to") if ARGV.length != 1
user = ARGV.first

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], base_url: "https://api.review.selfid.net", messaging_url: "wss://messaging.review.selfid.net/v1/messaging")

# Request display_name and email_address to the specified user
@app.request_information(user, [Selfid::FACT_DISPLAY_NAME, Selfid::FACT_EMAIL]) do |res|
  # Information request has been rejected by the user
  if res.status == "rejected"
    puts 'Information request rejected'
    exit!
  end

  # Response comes in form of facts easy to access with facts method
  puts "Hello #{res.fact(Selfid::FACT_DISPLAY_NAME).value}"
  exit!
end

# Wait for asyncrhonous process to finish
sleep 100
