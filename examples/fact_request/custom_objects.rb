# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative '../../lib/selfsdk'

# Process input data
abort("provide self_id to request information to") if ARGV.length != 1
user = ARGV.first
SelfSDK.logger = ::Logger.new($stdout).tap do |log|
  log.progname = "SelfSDK examples"
end if ENV.has_key?'LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}
storage_dir = "#{File.expand_path("..", File.dirname(__FILE__))}/self_storage"

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
puts 'connecting...'
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_DEVICE_SECRET"], ENV["STORAGE_KEY"], storage_dir, opts).start

# Create a custom fact and send it to the user.
puts 'issuing custom facts'


begin
  data = File.binread("my_image.png")
rescue => e
  puts "\u26A0 You must provide a PNG image to be stored as a user's fact"
  exit!
end
obj = @app.new_object("my_image", data, "image/png")

my_fact = SelfSDK::Services::Facts::Fact.new(
  "display image",
  obj,
  "source12")

@app.facts.issue(user, [my_fact])
sleep 5

# Request the custom fact
begin
  @app.facts.request(user, [{ fact: my_fact.key, issuers: [ENV["SELF_APP_ID"]] }]) do |res|
    # Information request has been rejected by the user
    if res.status == "rejected"
      puts 'Information request rejected'
      exit!
    end

    # Response comes in form of facts easy to access with facts method
    hash = res.attestation(my_fact.key.to_sym).value
    puts "Your stored fact is #{res.attestation(my_fact.key.to_sym).value}!"
    o = res.object(hash)

    o.save("/tmp/received.jpg")
    puts "Received object hash is #{o.object_hash}"
    exit!
  end
rescue => e
  puts "ERROR : #{e}"
  exit!
end

# Wait for asyncrhonous process to finish
sleep 1000
