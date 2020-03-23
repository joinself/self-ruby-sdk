# frozen_string_literal: true

require 'rqrcode'
require 'selfid'

# Disable the debug logs
Selfid.logger = Logger.new('/dev/null')

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"])
# Allows connections from everyone on self network to your app.
@app.permit_connection("*")

# Register an observer for an authentication response
@app.on_message Selfid::Messages::AuthenticationResp::MSG_TYPE do |auth|
  # The user has rejected the authentication
  if not auth.accepted?
    puts "Authentication request has been rejected"
    exit!
  end

  puts "User is now authenticated 🤘"
  exit
end

# Print a QR code to authenticate
req = @app.authenticate("-", request: false)

# Share resulting image with your users
png = RQRCode::QRCode.new(req, :level => 'l').as_png(
  border: 0,
  size: 400
)
IO.binwrite("/tmp/qr.png", png.to_s)

# This will open the exported qr.png with your default software,
# manually open /tmp/qr.png and scan it with your device if it
# does not work
p "Open /tmp/qr.png and scan it with your device"

# Wait for some time
sleep 100
