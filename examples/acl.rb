# frozen_string_literal: true

require_relative '../lib/selfid.rb'
user = "57340034173"

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"])

# Allow connections from "57340034173"
@app.permit_connection("57340034173")
connections = @app.allowed_connections
p connections

# Block connections from "57340034173"
@app.revoke_connection("57340034173")
connections = @app.allowed_connections
p connections

# Allow connections from "57340034173"
@app.permit_connection("57340034173")
connections = @app.allowed_connections
p connections
