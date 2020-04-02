# frozen_string_literal: true

require 'securerandom'
require "ed25519"
require 'json'
require 'net/http'
require 'rqrcode'
require_relative 'log'
require_relative 'jwt'
require_relative 'client'
require_relative 'messaging'
require_relative 'ntptime'
require_relative 'authenticated'
require_relative 'acl'
require_relative 'sources'
require_relative 'services/auth'
require_relative 'services/facts'
require_relative 'services/identity'
require_relative 'services/messaging'

# Namespace for classes and modules that handle Self interactions.
module Selfid
  # Abstract base class for CLI utilities. Provides some helper methods for
  # the option parser
  #
  # @attr_reader [Types] app_id the identifier of the current app.
  # @attr_reader [Types] app_key the api key for the current app.
  class App
    BASE_URL = "https://api.selfid.net".freeze
    MESSAGING_URL = "wss://messaging.selfid.net/v1/messaging".freeze

    attr_reader :app_id, :app_key, :client, :jwt
    attr_accessor :messaging_client

    # Initializes a Selfid App
    #
    # @param app_id [string] the app id.
    # @param app_key [string] the app api key provided by developer portal.
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :base_url The self provider url.
    # @option opts [String] :messaging_url The messaging self provider url.
    # @option opts [Bool] :auto_reconnect Automatically reconnects to websocket if connection is lost (defaults to true).
    # @option opts [String] :device_id The device id to be used by the app defaults to "1".
    def initialize(app_id, app_key, opts = {})
      @jwt = Selfid::Jwt.new(app_id, app_key)

      url = opts.fetch(:base_url, BASE_URL)
      Selfid.logger.info "client setup with #{url}"
      @client = RestClient.new(url, @jwt)

      messaging_url = opts.fetch(:messaging_url, MESSAGING_URL)
      unless messaging_url.nil?
        @messaging_client = MessagingClient.new(messaging_url,
                                                @jwt,
                                                @client,
                                                auto_reconnect: opts.fetch(:auto_reconnect, MessagingClient::DEFAULT_AUTO_RECONNECT),
                                                device_id: opts.fetch(:device_id, MessagingClient::DEFAULT_DEVICE),)
      end
    end

    # Provides access to Selfid::Services::Facts service
    def facts
      @facts ||= Selfid::Services::Facts.new(@messaging_client, @jwt, @identity)
    end

    # Provides access to Selfid::Services::Authentication service
    def authentication
      @authentication ||= Selfid::Services::Authentication.new(@messaging, @client, @jwt, @identity)
    end

    # Provides access to Selfid::Services::Identity service
    def identity
      @identity ||= Selfid::Services::Identity.new(@client)
    end

    # Provides access to Selfid::Services::Messaging service
    def messaging
      @messaging ||= Selfid::Services::Messaging.new(@messaging_client)
    end
  end
end
