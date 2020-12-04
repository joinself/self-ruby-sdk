# Copyright 2020 Self Group Ltd. All Rights Reserved.

require 'simplecov'

SimpleCov.start do
  add_filter '/test/'
  add_filter '/lib/version.rb'
end

require 'minitest/autorun'