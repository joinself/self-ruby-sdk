# frozen_string_literal: true

require 'sinatra'
require 'rqrcode'
require 'selfid'

class App < Sinatra::Base
  configure do
    # Disable the debug logs
    # Selfid.logger = Logger.new('/dev/null')

    # Connect your app to Self network, get your connection details creating a new
    # app on https://developer.selfid.net/
    app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"],
    base_url: "https://api.review.selfid.net", messaging_url:"wss://messaging.review.selfid.net/v1/messaging")

    # Allows connections from everyone on self network to your app.
    app.permit_connection("*")

    # Register an observer for an authentication response
    app.on_message Selfid::Messages::AuthenticationResp::MSG_TYPE do |auth|
      # The user has rejected the authentication
      if not auth.accepted?
        puts "Authentication request has been rejected"
        exit!
      end

      puts "User is now authenticated 🤘"
      exit
    end

    set :client, app
  end

  get '/' do
    # Print a QR code to authenticate
    req = settings.client.authenticate("-", request: false)

    # Share resulting image with your users
    png = RQRCode::QRCode.new(req, :level => 'l').as_png(
      border: 0,
      size: 400
    ).save('public/qr.png', :interlace => true)

    erb :index
  end
end
