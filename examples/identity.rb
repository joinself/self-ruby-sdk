# frozen_string_literal: true

require_relative '../lib/selfid.rb'

@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"])
identity = @app.identity("72921676292")
p identity
