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

    def facts
      @facts ||= Facts.new(self)
    end

    def authentication
      @authentication ||= Authentication.new(self)
    end

    def identity
      @identity ||= Identity.new(@client)
    end

    def messaging
      @messaging ||= Messaging.new(@messaging_client)
    end
  end

  class Messaging
    attr_accessor :client
    def initialize(client)
      @client = client
    end

    # Adds an observer for a message type
    #
    # @param type [string] message type (ex: Selfid::Messages::AuthenticationResp.MSG_TYPE
    # @param block [block] observer to be executed.
    def subscribe(type, &block)
      @client.type_observer[type] = block
    end

    # Permits incoming messages from the given identity.
    #
    # @param id [string] identity to be allowed
    def permit_connection(id)
      acl.allow id
    end

    # Lists allowed connections.
    def allowed_connections
      acl.list
    end

    # Revokes incoming messages from the given identity.
    #
    # @param id [string] identity to be denied
    def revoke_connection(id)
      acl.deny id
    end

    # Gets the current running app device_id
    def device_id
      @client.device_id
    end

    # Get the observer by uuid
    #
    # @param id [string] uuid of the observer to be retrieved
    def observer(id)
      @client.uuid_observer[id]
    end

    def set_observer(id, &block)
      @client.uuid_observer[id] = block
    end

    private

    def acl
      @acl ||= ACL.new(@client)
    end
  end

  class Identity
    def initialize(client)
      @client = client
    end

    # Gets an identity details
    #
    # @param self_id [string] identity SelfID
    def user(self_id)
      @client.identity(self_id)
    end

    # Gets an app defails
    #
    # @param self_id [string] app SelfID
    def app(self_id)
      @client.app(self_id)
    end

    # Gets an app/identity defails
    #
    # @param self_id [string] app/identity SelfID
    def get(self_id)
      @client.entity(self_id)
    end

    # Gets selfid registered devices
    #
    # @param self_id [string] identity/app selfID
    def devices(self_id)
      @client.devices(self_id)
    end
  end

  class Authentication
    def initialize(app)
      @app = app
    end

    # Sends an authentication request to the specified user_id.
    #
    # @param user_id [string] the receiver of the authentication request.
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :uuid The unique identifier of the authentication request.
    # @option opts [String] :async don't wait for the client to respond
    # @option opts [String] :jti specify the jti to be used.
    def request(user_id, opts = {}, &block)
      Selfid.logger.info "authenticating #{user_id}"
      uuid = opts.fetch(:uuid, SecureRandom.uuid)
      jti = opts.fetch(:jti, SecureRandom.uuid)
      async = opts.fetch(:async, false)
      body = {
        device_id: @app.messaging.device_id,
        typ: 'authentication_req',
        aud: @app.client.self_url,
        iss: @app.jwt.id,
        sub: user_id,
        iat: Selfid::Time.now.strftime('%FT%TZ'),
        exp: (Selfid::Time.now + 3600).strftime('%FT%TZ'),
        cid: uuid,
        jti: jti,
      }
      body = @app.jwt.prepare(body)
      return body if !opts.fetch(:request, true)

      if block_given?
        @app.messaging.set_observer uuid do |res|
          auth = authenticated?(res.input)
          yield(auth)
        end
        # when a block is given the request will always be asynchronous.
        async = true
      end

      Selfid.logger.info "authenticating uuid #{uuid}"
      if async
        @app.client.auth(body)
        return uuid
      end
      resp = @app.messaging.wait_for uuid do
        @app.client.auth(body)
      end
      authenticated?(resp.input)
    end

    def generate_qr(opts = {})
      req = request("-", request: false)
      ::RQRCode::QRCode.new(req, level: 'l').as_png(border: 0, size: 400)
    end

    # Adds an observer for an authentication response
    def subscribe(&block)
      @app.messaging.subscribe Selfid::Messages::AuthenticationResp::MSG_TYPE do |res|
        auth = authenticated?(res.input)
        yield(auth)
      end
    end

    private

    # Checks if the given input is an accepted authentication request.
    #
    # @param response [string] the response to an authentication request from self-api.
    # @return [Hash] Details response.
    #   * :accepted [Boolean] a bool describing if authentication is accepted or not.
    #   * :uuid [String] the request identifier.
    def authenticated?(response)
      Authenticated.new(valid_payload(response))
    end

    def valid_payload(response)
      jws = @app.jwt.parse(response)
      return nil unless jws.include? :payload

      payload = JSON.parse(@app.jwt.decode(jws[:payload]), symbolize_names: true)

      return nil if payload.nil?

      identity = @app.identity.get(payload[:sub])
      return nil if identity.nil?

      identity[:public_keys].each do |key|
        return payload if @app.jwt.verify(jws, key[:key])
      end
      nil
    rescue StandardError => e
      uuid = ""
      uuid = payload[:cid] unless payload.nil?
      Selfid.logger.error "error checking authentication for #{uuid} : #{e.message}"
      p e.backtrace
      nil
    end
  end

  class Facts
    def initialize(app)
      @app = app
    end

    # Request fact to an identity
    #
    # @param id [string] selfID to be requested
    # @param facts [array] list of facts to be requested
    # @option opts [String] :intermediary the intermediary selfid to be used.
    # @option opts [String] :type you can define if you want to request this information on a sync or an async way
    def request(id, facts, opts = {}, &block)
      async = opts.include?(:type) && (opts[:type] == :async)
      m = Selfid::Messages::IdentityInfoReq.new(@app.messaging.client)
      m.id = SecureRandom.uuid
      m.from = @app.jwt.id
      m.to = id
      m.facts = prepare_facts(facts)
      m.id = opts[:cid] if opts.include?(:cid)
      m.intermediary = opts[:intermediary] if opts.include?(:intermediary)
      m.description = opts[:description] if opts.include?(:description)
      return @app.jwt.prepare(m.body) if !opts.fetch(:request, true)

      devices = if opts.include?(:intermediary)
                  @app.identity.devices(opts[:intermediary])
                else
                  @app.identity.devices(id)
                end
      device = devices.first
      m.to_device = device

      if block_given?
        @app.messaging.set_observer(m.id, &block)
        # when a block is given the request will always be asynchronous.
        async = true
      end

      return m.send_message if async

      m.request
    end

    # Adds an observer for an fact response
    def subscribe(&block)
      @app.messaging.subscribe(Selfid::Messages::IdentityInfoResp::MSG_TYPE, &block)
    end

    def generate_qr(facts)
      req = request("-", facts, request: false)
      ::RQRCode::QRCode.new(req, level: 'l').as_png(border: 0, size: 400)
    end

    private

    # fills facts with default values
    def prepare_facts(fields)
      fs = []
      fields.each do |f|
        fs << if f.is_a?(Hash)
                f
              else
                { fact: f }
              end
      end
      fs
    end
  end
end
