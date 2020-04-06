# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)
require_relative "lib/version"

Gem::Specification.new do |s|
  s.name = 'selfid'
  s.version = Selfid::VERSION
  s.date = '2011-09-29'
  s.summary = 'self id gem'
  s.authors = ["Aldgate Ventures"]
  s.homepage = "https://www.selfid.net/"
  s.files = [
    "lib/selfid.rb",
    "lib/client.rb",
    "lib/messaging.rb",
    "lib/log.rb",
    "lib/jwt.rb",
    "lib/ntptime.rb",
    "lib/authenticated.rb",
    "lib/acl.rb",
    "lib/sources.rb",
    "lib/proto/",
    "lib/proto/acl_pb.rb",
    "lib/proto/aclcommand_pb.rb",
    "lib/proto/auth_pb.rb",
    "lib/proto/errtype_pb.rb",
    "lib/proto/header_pb.rb",
    "lib/proto/message_pb.rb",
    "lib/proto/msgtype_pb.rb",
    "lib/proto/notification_pb.rb",
    "lib/messages/",
    "lib/messages/base.rb",
    "lib/messages/fact.rb",
    "lib/messages/attestation.rb",
    "lib/messages/identity_info_req.rb",
    "lib/messages/identity_info_resp.rb",
    "lib/messages/authentication_resp.rb",
    "lib/messages/authentication_req.rb",
    "lib/messages/message.rb",
    "lib/services/auth.rb",
    "lib/services/facts.rb",
    "lib/services/identity.rb",
    "lib/services/messaging.rb"
  ]
  s.require_paths = ["lib", "lib/proto", "lib/messages", "lib/services"]
  s.add_dependency "async"
  s.add_dependency "ed25519"
  s.add_dependency "eventmachine"
  s.add_dependency "faye-websocket"
  s.add_dependency "google-protobuf"
  s.add_dependency "httparty"
  s.add_dependency "logger"
  s.add_dependency "net-ntp"
  s.add_dependency "rqrcode"
  s.add_development_dependency "bundler", "~> 1.12"
  s.add_development_dependency "minitest"
  s.add_development_dependency "pry"
  s.add_development_dependency "rake", "~> 12.3"
  s.add_development_dependency "rubocop", "~> 0.49"
  s.add_development_dependency "timecop"
  s.add_development_dependency "webmock"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
end
