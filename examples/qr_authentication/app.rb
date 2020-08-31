# frozen_string_literal: true

require 'selfsdk'

# Disable the debug logs
SelfSDK.logger = Logger.new('/dev/null') if ENV.has_key?'NO_LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], ENV["STORAGE_KEY"], opts)

# Register an observer for an authentication response
@app.authentication.subscribe do |auth|
  # The user has rejected the authentication
  if not auth.accepted?
    puts "Authentication request has been rejected"
    exit!
  end

  puts "User is now authenticated 🤘"
  exit
end

# Generate a QR code to authenticate
@app.authentication
    .generate_qr
    .as_png(border: 0, size: 400)
    .save('/tmp/qr.png', :interlace => true)
`open /tmp/qr.png`

# This will open the exported qr.png with your default software,
# manually open /tmp/qr.png and scan it with your device if it
# does not work
p "Open /tmp/qr.png and scan it with your device"

# Wait for some time
sleep 100
