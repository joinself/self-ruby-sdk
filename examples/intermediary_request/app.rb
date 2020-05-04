# frozen_string_literal: true

require 'selfid'

# Process input data
abort("provide self_id to request information to") if ARGV.length != 1
user = ARGV.first
Selfid.logger = Logger.new('/dev/null') if ENV.has_key?'NO_LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_BASE_URL') ? { base_url: ENV["SELF_BASE_URL"], messaging_url: ENV["SELF_MESSAGING_URL"] } : {}

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfid.net/
@app = Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], opts)

# Even its a silly test lets check if the user's email is equal test@test.org
# without ever leaking information about the user's fact.
res_opts = {}
res_opts[:intermediary] = ENV['SELF_INTERMEDIARY'] if ENV.has_key?('SELF_INTERMEDIARY')
res = @app.facts.request_via_intermediary(user, [{ sources: [Selfid::SOURCE_USER_SPECIFIED],
                                                         fact: Selfid::FACT_EMAIL,
                                                         operator: '==',
                                                         expected_value: 'test@test.org' }], res_opts)

if res.nil? # The request can timeout
  p "Request has timed out"
elsif res.accepted? # The user accepts the intermediary request
  p "Request has been accepted"
  p "Your assertion is #{res.fact(Selfid::FACT_EMAIL).attestations.first.value}"
elsif res.rejected? # The user rejects the intermediary request
  p "Request has been rejected"
elsif res.unauthorized? # You're not a connection for the specified user
  p "You're not authorized to interact with this user"
elsif res.errored? # An error occured
  p "An error occured"
end

