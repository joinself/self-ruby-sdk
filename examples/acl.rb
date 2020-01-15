# frozen_string_literal: true

require_relative '../lib/selfid.rb'
user = "57340034173"

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"])

# Allow connections from "57340034173"
@app.acl.allow("57340034173")
connections = @app.acl.list
p connections

# Block connections from "57340034173"
@app.acl.block("57340034173")
connections = @app.acl.list
p connections

# Allow connections from "57340034173"
@app.acl.allow("57340034173")
connections = @app.acl.list
p connections