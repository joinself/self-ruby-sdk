# frozen_string_literal: true

require 'logger'

module Selfid
  class << self
    attr_writer :logger

    def logger
      @logger ||= ::Logger.new($stdout).tap do |log|
        log.progname = name
      end
    end
  end
end
