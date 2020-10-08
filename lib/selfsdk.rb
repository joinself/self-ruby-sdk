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
require_relative 'services/facts'
require_relative 'services/identity'
require_relative 'services/messaging'

# Namespace for classes and modules that handle Self interactions.
module SelfSDK
  # Abstract base class for CLI utilities. Provides some helper methods for
  # the option parser
  #
  # @attr_reader [Types] app_id the identifier of the current app.
  # @attr_reader [Types] app_key the api key for the current app.
  class App
    BASE_URL = "https://api.joinself.com".freeze
    MESSAGING_URL = "wss://messaging.joinself.com/v1/messaging".freeze

    attr_reader :client
    attr_accessor :messaging_client

    # Initializes a SelfSDK App
    #
    # @param app_id [string] the app id.
    # @param app_key [string] the app api key provided by developer portal.
    # @param storage_key [string] the key to be used to encrypt persisted data.
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :base_url The self provider url.
    # @option opts [String] :messaging_url The messaging self provider url.
    # @option opts [Bool] :auto_reconnect Automatically reconnects to websocket if connection is lost (defaults to true).
    # @option opts [Symbol] :env The environment to be used, defaults to ":production".
    # @option opts [String] :storage_dir The folder where encryption sessions and settings will be stored
    def initialize(app_id, app_key, storage_key, opts = {})
      SelfSDK.logger.debug "syncing ntp times #{SelfSDK::Time.now}"
      env = opts.fetch(:env, "")

      @client = RestClient.new(base_url(opts), app_id, app_key, env)
      messaging_url = messaging_url(opts)
      unless messaging_url.nil?
        @messaging_client = MessagingClient.new(messaging_url,
                                                @client,
                                                storage_dir: opts.fetch(:storage_dir, MessagingClient::DEFAULT_STORAGE_DIR),
                                                auto_reconnect: opts.fetch(:auto_reconnect, MessagingClient::DEFAULT_AUTO_RECONNECT),
                                                device_id: opts.fetch(:device_id, MessagingClient::DEFAULT_DEVICE))
      end
    end

    # Provides access to SelfSDK::Services::Facts service
    def facts
      @facts ||= SelfSDK::Services::Facts.new(messaging, @client)
    end

    # Provides access to SelfSDK::Services::Authentication service
    def authentication
      @authentication ||= SelfSDK::Services::Authentication.new(messaging, @client)
    end

    # Provides access to SelfSDK::Services::Identity service
    def identity
      @identity ||= SelfSDK::Services::Identity.new(@client)
    end

    # Provides access to SelfSDK::Services::Messaging service
    def messaging
      @messaging ||= SelfSDK::Services::Messaging.new(@messaging_client)
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

      def base_url(opts)
        return opts[:base_url] if opts.key? :base_url
        return "https://api.#{opts[:env].to_s}.joinself.com" if opts.key? :env
        BASE_URL
      end

      def messaging_url(opts)
        return opts[:messaging_url] if opts.key? :messaging_url
        return "wss://messaging.#{opts[:env].to_s}.joinself.com/v1/messaging" if opts.key? :env
        MESSAGING_URL
      end

  end
end
