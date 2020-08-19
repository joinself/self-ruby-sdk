# frozen_string_literal: true

require 'selfid'

# Process input data
abort("provide self_id to request information to") if ARGV.length != 1
user = ARGV.first
Selfid.logger = Logger.new('/dev/null') if ENV.has_key?'NO_LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], ENV["STORAGE_KEY"], opts)

begin
  # Request display_name and email_address to the specified user
  res = @app.facts.request(user, [Selfid::FACT_DISPLAY_NAME, Selfid::FACT_EMAIL])

  # Information request has been rejected by the user
  if res.status == "rejected"
    puts 'Information request rejected'
    exit!
  end

  # Response comes in form of facts easy to access with facts method
  puts "Hello #{res.fact(Selfid::FACT_DISPLAY_NAME).attestations.first.value}"
rescue => e
  puts "ERROR : #{e}"
  exit!
end
