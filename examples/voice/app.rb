# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative '../../lib/selfsdk'

# Process input data
abort("provide self_id to request information to") if ARGV.length != 2
operator = ARGV.first
customer = ARGV[1]
SelfSDK.logger = ::Logger.new($stdout).tap do |log|
  log.progname = "SelfSDK examples"
end if ENV.has_key?'LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}
storage_dir = "#{File.expand_path("..", File.dirname(__FILE__))}/self_storage"

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_DEVICE_SECRET"], ENV["STORAGE_KEY"], storage_dir, opts)

# Request display_name and email_address to the specified user
begin
  @app.voice.on_start do |issuer, payload|
    # Redirect the call to a second user
    puts "[app] received start from #{issuer}, redirecting..."
    @app.voice.start customer, payload[:cid], payload[:call_id], payload[:peer_info], { operator_name: "Supu" }
  end

  @app.voice.on_accept do |issuer, payload|
    puts "[app] received acceptation from #{issuer}, redirecting..."
    @app.voice.accept operator, payload[:cid], payload[:call_id], payload[:peer_info]
  end

  @app.voice.on_stop do |issuer, payload|
    puts "[app] received stop from #{issuer}, redirecting..."
    if issuer == operator
      puts "[app] ... to customer"
      @app.voice.stop customer, payload[:cid], payload[:call_id]
    else
      puts "[app] ... to operator"
      @app.voice.stop operator, payload[:cid], payload[:call_id]
    end
  end

  @app.voice.on_busy do |issuer, payload|
    puts "[app] received busy from #{issuer}, redirecting..."
    if issuer == operator
      @app.voice.busy customer, payload[:cid], payload[:call_id]
    else
      @app.voice.busy operator, payload[:cid], payload[:call_id]
    end
  end

  puts "[app] sending setup request to #{operator}"
  @app.voice.setup(operator, "Bob", "cid")
rescue => e
  puts "ERROR : #{e}"
  exit!
end

# Wait for asyncrhonous process to finish
sleep 1000
