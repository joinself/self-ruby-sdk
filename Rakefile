# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new do |t|
  ENV['TZ'] = 'UTC'
  t.pattern = "test/**/*_test.rb"
end

desc "Run tests"
task default: :test

namespace :bump do
  require 'semantic'
  require_relative "lib/version"
  current_version = Semantic::Version.new Selfid::VERSION
    
  task :major do
    new_version = current_version.increment!(:major)
    bump_version(new_version)
  end

  task :minor do
    new_version = current_version.increment!(:minor)
    bump_version(new_version)
  end

  task :patch do
    new_version = current_version.increment!(:patch)
    bump_version(new_version)
  end
end

def bump_version(version)
  versionfile = "./lib/version.rb"

  text = File.read(versionfile)
  replace = text.gsub(/VERSION = .*/, "VERSION = \"#{version}\"")
  File.open(versionfile, "w") {|file| file.puts replace}

  sh "bundle", "install"
end
