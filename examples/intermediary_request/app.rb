# frozen_string_literal: true

require 'selfsdk'

# Process input data
abort("provide self_id to request information to") if ARGV.length != 1
user = ARGV.first
SelfSDK.logger = Logger.new('/dev/null') if ENV.has_key?'NO_LOGS'

# You can point to a different environment by passing optional values to the initializer
opts = ENV.has_key?('SELF_BASE_URL') ? { base_url: ENV["SELF_BASE_URL"], messaging_url: ENV["SELF_MESSAGING_URL"] } : {}

# Connect your app to Self network, get your connection details creating a new
# app on https://developer.selfsdk.net/
@app = SelfSDK::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], ENV["STORAGE_KEY"], opts)

# Even its a silly test lets check if the user's email is equal test@test.org
# without ever leaking information about the user's fact.
res_opts = {}
res_opts[:intermediary] = ENV['SELF_INTERMEDIARY'] if ENV.has_key?('SELF_INTERMEDIARY')
res = @app.facts.request_via_intermediary(user, [{ sources: [:user_specified],
                                                         fact: :email_address,
                                                         operator: :equals,
                                                         expected_value: 'test@test.org' }], res_opts)

if res.nil? # The request can timeout
  p "Request has timed out"
elsif res.accepted? # The user accepts the intermediary request
  p "Request has been accepted"
  p "Your assertion is #{res.attestation_values_for(:email_address).first}"
elsif res.rejected? # The user rejects the intermediary request
  p "Request has been rejected"
elsif res.unauthorized? # You're not a connection for the specified user
  p "You're not authorized to interact with this user"
elsif res.errored? # An error occured
  p "An error occured"
end

