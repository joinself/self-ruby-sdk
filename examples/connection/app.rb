# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative '../../lib/selfsdk'

# Disable the debug logs
SelfSDK.logger = ::Logger.new($stdout).tap do |log|
  log.progname = "SelfSDK examples"
end if ENV.has_key?'LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}
storage_dir = "#{File.expand_path("..", File.dirname(__FILE__))}/self_storage"

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_DEVICE_SECRET"], ENV["STORAGE_KEY"], storage_dir, opts)

# Register an observer for a connection response
@app.chat.on_connection do |res|
  if res.status == "accepted"
    p "successfully connected"
    @app.chat.message(res.from, "Hey there! We're connected!")
  end
end

# Generate a QR code for the connection request
@app.chat
    .generate_connection_qr
    .as_png(border: 0, size: 400)
    .save('/tmp/qr.png', :interlace => true)

# This will open the exported qr.png with your default software,
# manually open /tmp/qr.png and scan it with your device if it
# does not work

# You can manage your redirection codes on your app management on the
# developer portal
redirection_code = "90d017d1"
link = @app.chat.generate_connection_deep_link(redirection_code)
p "Scan /tmp/qr.png with your device"
`open /tmp/qr.png`
p "or click this link \n\n #{link} \n\non your mobile phone"

# Wait for some time
sleep 1000
