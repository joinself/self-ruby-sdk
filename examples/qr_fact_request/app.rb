# frozen_string_literal: true

require 'selfid'

# Disable the debug logs
Selfid.logger = Logger.new('/dev/null') if ENV.has_key?'NO_LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_BASE_URL') ? { base_url: ENV["SELF_BASE_URL"], messaging_url: ENV["SELF_MESSAGING_URL"] } : {}

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], opts)

# Register an observer for an information response
@app.messaging.subscribe :fact_response do |res|
  # Information request has been rejected by the user
  if res.status == "rejected"
    puts 'Information request rejected'
    exit!
  end

  # Response comes in form of facts easy to access with facts method
  puts "Hello #{res.fact(Selfid::FACT_DISPLAY_NAME).attestations.first.value}"
  exit!
end

# Generate a QR code for the information request
png = @app.facts.generate_qr([Selfid::FACT_DISPLAY_NAME]).as_png(border: 0, size: 400)
IO.binwrite("/tmp/qr.png", png.to_s)

# This will open the exported qr.png with your default software,
# manually open /tmp/qr.png and scan it with your device if it
# does not work
p "Scan /tmp/qr.png with your device"
`open /tmp/qr.png`

# Wait for some time
sleep 100
