# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require 'securerandom'
require "ed25519"
require 'json'
require 'net/http'
require 'rqrcode'
require_relative 'log'
require_relative 'jwt_service'
require_relative 'signature_graph'
require_relative 'client'
require_relative 'messaging'
require_relative 'ntptime'
require_relative 'authenticated'
require_relative 'acl'
require_relative 'sources'
require_relative 'services/auth'
require_relative 'services/requester'
require_relative 'services/facts'
require_relative 'services/identity'
require_relative 'services/messaging'
require_relative 'services/chat'
require_relative 'services/docs'
require_relative 'services/voice'

# Namespace for classes and modules that handle Self interactions.
module SelfSDK
  # Abstract base class for CLI utilities. Provides some helper methods for
  # the option parser
  #
  # @attr_reader [Types] app_id the identifier of the current app.
  # @attr_reader [Types] app_key the api key for the current app.
  class App
    BASE_URL = "https://api.joinself.com".freeze
    MESSAGING_URL = "wss://messaging.joinself.com/v2/messaging".freeze

    attr_reader :client, :started
    attr_accessor :messaging_client

    # Initializes a SelfSDK App
    #
    # @param app_id [string] the app id.
    # @param app_key [string] the app api key provided by developer portal.
    # @param storage_key [string] the key to be used to encrypt persisted data.
    # @param storage_dir [String] The folder where encryption sessions and settings will be stored
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :base_url The self provider url.
    # @option opts [String] :messaging_url The messaging self provider url.
    # @option opts [Bool] :auto_reconnect Automatically reconnects to websocket if connection is lost (defaults to true).
    # @option opts [Symbol] :env The environment to be used, defaults to ":production".
    def initialize(app_id, app_key, storage_key, storage_dir, opts = {})
      app_key = cleanup_key(app_key)

      SelfSDK.logger.debug "syncing ntp times #{SelfSDK::Time.now}"
      env = opts.fetch(:env, "")
      env = "" if env == "production"

      @client = RestClient.new(base_url(opts), app_id, app_key, env)
      messaging_url = messaging_url(opts)
      @started = false
      unless messaging_url.nil?
        @messaging_client = MessagingClient.new(messaging_url,
                                                @client,
                                                storage_key,
                                                storage_dir: storage_dir,
                                                auto_reconnect: opts.fetch(:auto_reconnect, MessagingClient::DEFAULT_AUTO_RECONNECT),
                                                device_id: opts.fetch(:device_id, MessagingClient::DEFAULT_DEVICE))
      end
    end

    # Starts the websockets connection and processes incoming messages in case the client
    # is initialized with auto_start set to false.
    def start
      return self if @started

      @messaging_client.start
      @started = true

      self
    end

    # Provides access to SelfSDK::Services::Facts service
    def facts
      @facts ||= SelfSDK::Services::Facts.new(requester)
    end

    # Provides access to SelfSDK::Services::Authentication service
    def authentication
      @authentication ||= SelfSDK::Services::Authentication.new(requester)
    end

    # Provides access to SelfSDK::Services::Identity service
    def identity
      @identity ||= SelfSDK::Services::Identity.new(@client)
    end

    # Provides access to SelfSDK::Services::Messaging service
    def messaging
      @messaging ||= SelfSDK::Services::Messaging.new(@messaging_client)
    end

    # Provides access to SelfSDK::Services::Chat service
    def chat
      @chat ||= SelfSDK::Services::Chat.new(messaging, identity)
    end

    # Provides access to SelfSDK::Services::Voice service
    def voice
      @voice ||= SelfSDK::Services::Voice.new(messaging)
    end

    # Provides access to SelfSDK::Services::Docs service
    def docs
      @docs ||= SelfSDK::Services::Docs.new(messaging, @client.self_url)
    end

    def app_id
      client.jwt.id
    end

    def app_key
      client.jwt.key
    end

    # Closes the websocket connection
    def close
      @messaging_client.close
    end

    protected

      def requester
        @requester ||= SelfSDK::Services::Requester.new(messaging, @client)
      end

      def base_url(opts)
        return opts[:base_url] if opts.key? :base_url
        return "https://api.#{opts[:env].to_s}.joinself.com" if opts.key? :env
        BASE_URL
      end

      def messaging_url(opts)
        return opts[:messaging_url] if opts.key? :messaging_url
        return "wss://messaging.#{opts[:env].to_s}.joinself.com/v2/messaging" if opts.key? :env
        MESSAGING_URL
      end

      def cleanup_key(key)
        return key unless key.include? '_'
  
        key.split('_').last
      end
    
  end
end
