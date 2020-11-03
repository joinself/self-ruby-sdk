# frozen_string_literal: true

require_relative '../../lib/selfsdk.rb'

# Process input data
abort("provide self_id to authenticate") if ARGV.length != 1
user = ARGV.first
SelfSDK.logger = Logger.new('/dev/null') if ENV.has_key?'NO_LOGS'

# You can point to a different environment by passing optional values to the initializer
#opts = { base_url: "http://localhost:8080", messaging_url: "ws://localhost:8086/v1/messaging"}
opts = {env: "review"}
opts[:storage_dir] = "#{File.expand_path("..", File.dirname(__FILE__))}/.self_storage"
puts opts[:storage_dir]

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], ENV["STORAGE_KEY"], opts)

# Authenticate a user to your app.
puts "Sending an authentication request to your device..."
begin
  @app.authentication.request user do |auth|
    # The user has rejected the authentication
    if not auth.accepted?
      puts "Authentication request has been rejected"
      exit!
    end

    puts "User is now authenticated 🤘"
    exit!
  end
rescue => e
  puts "ERROR : #{e}"
  exit!
end
# Wait for asyncrhonous process to finish
sleep 100
