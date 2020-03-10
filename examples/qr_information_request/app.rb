# frozen_string_literal: true

require 'rqrcode'

require_relative '../../lib/selfid.rb'

# Disable the debug logs
Selfid.logger = Logger.new('/dev/null')

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"])
# Allows connections from everyone on self network to your app.
@app.permit_connection("*")

# Register an observer for an information response
@app.on_message Selfid::Messages::IdentityInfoResp::MSG_TYPE do |res|
  # Information request has been rejected by the user
  if res.status == "rejected"
    puts 'Information request rejected'
    exit!
  end

  # Response comes in form of facts easy to access with facts method
  puts "Hello #{res.fact(Selfid::FACT_DISPLAY_NAME).value}"
  exit!
end

# Print a QR code for the information request
req = @app.request_information(user, [Selfid::FACT_DISPLAY_NAME], request: false)

# Share resulting image with your users
png = RQRCode::QRCode.new(req, :level => 'l').as_png(
  border: 0,
  size: 400
)
IO.binwrite("/tmp/qr.png", png.to_s)

# This will open the exported qr.png with your default software, 
# manually open /tmp/qr.png and scan it with your device if it 
# does not work
p "Scan /tmp/qr.png with your device"
`open /tmp/qr.png`

# Wait for some time
sleep 100
