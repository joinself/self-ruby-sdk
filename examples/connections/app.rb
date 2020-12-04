# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'selfsdk'

# Process input data
abort("provide self_id to authenticate") if ARGV.length != 1
user = ARGV.first
SelfSDK.logger = Logger.new('/dev/null')

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}
opts[:storage_dir] = "#{File.expand_path("..", File.dirname(__FILE__))}/.self_storage"

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], ENV["STORAGE_KEY"], opts)

puts "CONNECTIONS EXAMPLE"
# Remove all existing connections
connections = @app.messaging.allowed_connections
puts "List existing connections"
puts " - connections : #{connections.join(",")}"

# Block connections from *
puts "Block all connections"
@app.messaging.revoke_connection("*")

# List should be empty
connections = @app.messaging.allowed_connections
puts " - connections : #{connections.join(",")}"

# Allow connections from 1112223334
puts "Permit connections from a specific ID"
@app.messaging.permit_connection(user)
connections = @app.messaging.allowed_connections
puts " - connections : #{connections.join(",")}"

# Allow connections from *
puts "Permit all connections (replaces all other entries with a wildcard entry)"
@app.messaging.permit_connection("*")
connections = @app.messaging.allowed_connections
puts " - connections : #{connections.join(",")}"
puts ""

# Allow connections from 1112223334
puts "Permit connection from a specific ID (no change as the list already contains a wildcard entry)"
@app.messaging.permit_connection(user)
connections = @app.messaging.allowed_connections
puts " - connections : #{connections.join(",")}"
puts ""
