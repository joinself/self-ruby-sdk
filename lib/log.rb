# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'logger'

module SelfSDK
  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new('/dev/null')

      #@logger ||= ::Logger.new($stdout).tap do |log|
      #  log.progname = name
      #end
    end
  end
end
