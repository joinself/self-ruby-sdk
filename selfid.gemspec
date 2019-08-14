$:.push File.expand_path("../lib", __FILE__)
require_relative "lib/version"

Gem::Specification.new do |s|
  s.name = %q{selfid}
  s.version = Selfid::VERSION
  s.date = %q{2011-09-29}
  s.summary = %q{self id gem}
  s.authors = [ "Aldgate Ventures"]
  s.homepage    = "https://www.selfid.net/"
  s.files = [
    "lib/selfid.rb"
  ]
  s.require_paths = ["lib"]
  s.add_development_dependency "bundler", "~> 1.12"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "minitest"
  s.add_development_dependency "webmock"
  s.add_development_dependency "timecop"
  s.add_development_dependency "ed25519"
end
