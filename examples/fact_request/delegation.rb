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
puts 'issuing a delegation certificate to allow authentication'
my_group = SelfSDK::Services::Facts::Group.new("Delegated actions", "plane") 
cert = SelfSDK::Services::Facts::Delegation.new(
  [ user ],
  ['authenticate'],
  "allow",
  ['resources:appID2:authentication'],
).encode

my_fact = SelfSDK::Services::Facts::Fact.new(
  "authentication2",
  cert,
  "authentication",
  display_name: "Delegated authentication",
  group: my_group,
  type: SelfSDK::Services::Facts::Delegation::TYPE
)

@app.facts.issue(user, [my_fact])
sleep 5

# Request the custom fact
begin
  puts "requesting auth delegation "
  @app.facts.request(user, [{ fact: my_fact.key, issuers: [ENV["SELF_APP_ID"]] }]) do |res|
    # Information request has been rejected by the user
    if res.status == "rejected"
      puts 'Information request rejected'
      exit!
    end

    # Response comes in form of facts easy to access with facts method
    attestation = res.attestations_for(my_fact.key.to_sym).first
    att = SelfSDK::Services::Facts::Delegation.parse(attestation.value)

    puts "User '#{att.subjects.join(',')}' sent a proof he's '#{att.effect}ed' to '#{att.actions.join(",")}' on behalf of '#{attestation.origin}'!"
    exit!
  end
rescue => e
  puts "ERROR : #{e}"
  exit!
end

# Wait for asyncrhonous process to finish
sleep 1000
