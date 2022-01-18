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


=begin
puts "Write your message and hit enter".green
Thread.new do
  while b = get_input do
    m = @app.chat.message(user, b)
    sleep 5
    m.edit("no way!")
    sleep 5
    m.delete!
  end
end
=end


@app.chat.subscribe_to_messages do |msg|
  msg.mark_as_delivered
  msg.mark_as_read
  msg.respond("hi!")

  resp = msg.message("howre you doin?")
  sleep 2
  resp.edit("how're you doing?")
  sleep 3
  resp.delete!
end

=begin
#Thread.new do 
  @app.messaging.subscribe :chat_message do |msg|
    # Mark the message as read
    @app.chat.delivered(user, msg.id)
    # Mark the message as delivered
    @app.chat.read(user, msg.id)
    # Print the incoming message
    puts "Bob:".red
    puts msg.body  
  end  
end
=end

sleep 100000