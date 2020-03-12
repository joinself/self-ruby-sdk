# frozen_string_literal: true

require 'selfid'

# Process input data
abort("provide self_id to authenticate") if ARGV.length != 1
user = ARGV.first

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"])

# Allow connections from user
@app.permit_connection(user)
connections = @app.allowed_connections
p connections

# Block connections from user
@app.revoke_connection(user)
connections = @app.allowed_connections
p connections

# Allow connections from user
@app.permit_connection(user)
connections = @app.allowed_connections
p connections
