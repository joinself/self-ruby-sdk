# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative '../../lib/selfsdk'
require_relative '../utilities/colorize.rb'

def get_input
  STDIN.gets.chomp
end

# Process input data
abort("provide self_id to authenticate") if ARGV.length != 1
user = ARGV.first

SelfSDK.logger = ::Logger.new($stdout).tap do |log|
  log.progname = "SelfSDK examples"
end if ENV.has_key?'LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}
storage_dir = "#{File.expand_path("..", File.dirname(__FILE__))}/self_storage"

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_DEVICE_SECRET"], ENV["STORAGE_KEY"], storage_dir, opts)

@app.messaging.permit_connection("*")

@app.messaging.subscribe :chat_message do |msg|
  # Mark the message as read
  @app.chat.delivered(user, msg.id)
  # Mark the message as delivered
  @app.chat.read(user, msg.id)
  # Print the incoming message
  puts "Bob:".red
  puts msg.body

  puts "You:".green
  b = get_input
  @app.chat.message(user, b)
end

puts "You:".green
b = get_input
@app.chat.message(user, b)

sleep 100000