# frozen_string_literal: true

require 'selfid'

# Process input data
abort("provide self_id to request information to") if ARGV.length != 1
user = ARGV.first

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], base_url: "https://api.review.selfid.net", messaging_url: "wss://messaging.review.selfid.net/v1/messaging")

# Even its a silly test lets check if the user's email is equal test@test.org
# without ever leaking information about the user's fact.
res = @app.request_information(user, [{
  source: Selfid::SOURCE_USER_SPECIFIED,
  fact: Selfid::FACT_EMAIL,
  operator: '==',
  value: 'test@test.org'
}], intermediary: ENV['SELF_INTERMEDIARY'], type: :sync)

if res.nil? # The request can timeout
  p "Request has timed out"
elsif res.accepted? # The user accepts the intermediary request
  p "Request has been accepted"
  p "Your assertion is #{res.fact(Selfid::FACT_EMAIL).result}"
elsif res.rejected? # The user rejects the intermediary request
  p "Request has been rejected"
elsif res.unauthorized? # You're not a connection for the specified user
  p "You're not authorized to interact with this user"
elsif res.errored? # An error occured
  p "An error occured"
end

