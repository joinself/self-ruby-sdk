# frozen_string_literal: true

require 'selfid'

# Process input data
abort("provide self_id to authenticate") if ARGV.length != 1
user = ARGV.first

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_BASE_URL') ? { base_url: ENV["SELF_BASE_URL"], messaging_url: ENV["SELF_MESSAGING_URL"] } : {}

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], opts)

# Allow connections from user
@app.messaging.permit_connection(user)
connections = @app.messaging.allowed_connections
p connections

# Block connections from user
@app.messaging.revoke_connection(user)
connections = @app.messaging.allowed_connections
p connections

# Allow connections from user
@app.messaging.permit_connection(user)
connections = @app.messaging.allowed_connections
p connections
