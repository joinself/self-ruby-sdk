# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new do |t|
  ENV['TZ'] = 'UTC'
  t.libs << 'test'
end

desc "Run tests"
task default: :test
