# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)
require_relative "lib/version"

Gem::Specification.new do |s|
  s.name = 'selfsdk'
  s.version = SelfSDK::VERSION
  s.license = 'MIT'
  s.date = '2011-09-29'
  s.summary = 'joinself sdk'
  s.authors = ["Aldgate Ventures"]
  s.homepage = "https://www.joinself.com/"
  s.files = [
    "lib/selfsdk.rb",
    "lib/client.rb",
    "lib/messaging.rb",
    "lib/crypto.rb",
    "lib/log.rb",
    "lib/jwt_service.rb",
    "lib/ntptime.rb",
    "lib/authenticated.rb",
    "lib/signature_graph.rb",
    "lib/acl.rb",
    "lib/sources.rb",
    "lib/messages/",
    "lib/messages/base.rb",
    "lib/messages/fact.rb",
    "lib/messages/attestation.rb",
    "lib/messages/fact_request.rb",
    "lib/messages/fact_response.rb",
    "lib/messages/chat.rb",
    "lib/messages/chat_message.rb",
    "lib/messages/chat_message_read.rb",
    "lib/messages/chat_message_delivered.rb",
    "lib/messages/chat_invite.rb",
    "lib/messages/chat_join.rb",
    "lib/messages/chat_remove.rb",
    "lib/messages/authentication_resp.rb",
    "lib/messages/authentication_req.rb",
    "lib/messages/authentication_message.rb",
    "lib/messages/message.rb",
    "lib/services/auth.rb",
    "lib/services/facts.rb",
    "lib/services/identity.rb",
    "lib/services/messaging.rb",
    "lib/services/chat.rb",
    "lib/chat/file_object.rb",
    "lib/chat/group.rb",
    "lib/chat/message.rb"
  ]
  s.require_paths = ["lib", "lib/messages", "lib/services"]
  s.add_dependency "self_crypto"
  s.add_dependency "self_msgproto"
  s.add_dependency "async"
  s.add_dependency "ed25519"
  s.add_dependency "eventmachine"
  s.add_dependency "faye-websocket"
  s.add_dependency "google-protobuf"
  s.add_dependency "httparty"
  s.add_dependency "logger"
  s.add_dependency "net-ntp"
  s.add_dependency "rqrcode"
  s.add_dependency "jwt"
  s.add_development_dependency "bundler", "~> 1.12"
  s.add_development_dependency "minitest"
  s.add_development_dependency "pry"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "rubocop", "~> 0.49"
  s.add_development_dependency "timecop"
  s.add_development_dependency "webmock"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "semantic"
end
