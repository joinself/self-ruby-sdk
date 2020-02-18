# frozen_string_literal: true

require 'securerandom'
require "ed25519"
require 'json'
require 'net/http'
require_relative 'log'
require_relative 'jwt'
require_relative 'client'
require_relative 'messaging'
require_relative 'ntptime'
require_relative 'authenticated'
require_relative 'acl'

# Namespace for classes and modules that handle Self interactions.
module Selfid
  # Abstract base class for CLI utilities. Provides some helper methods for
  # the option parser
  #
  # @attr_reader [Types] app_id the identifier of the current app.
  # @attr_reader [Types] app_key the api key for the current app.
  class App
    BASE_URL = "https://api.selfid.net"
    MESSAGING_URL = "wss://messaging.selfid.net/v1/messaging"

    attr_reader :app_id, :app_key, :client, :jwt
    attr_accessor :messaging

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
      if not messaging_url.nil?
        @messaging = MessagingClient.new(messaging_url, 
                                         @jwt, 
                                         @client, 
                                         auto_reconnect: opts.fetch(:auto_reconnect, MessagingClient::DEFAULT_AUTO_RECONNECT),
                                         device_id: opts.fetch(:device_id, MessagingClient::DEFAULT_DEVICE),
                                        )
        @acl = ACL.new(@messaging)
      end
    end

    # Sends an authentication request to the specified user_id.
    #
    # @param user_id [string] the receiver of the authentication request.
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :uuid The unique identifier of the authentication request.
    # @option opts [String] :async don't wait for the client to respond
    # @option opts [String] :jti specify the jti to be used.
    def authenticate(user_id, opts = {}, &block)
      Selfid.logger.info "authenticating #{user_id}"
      uuid = opts.fetch(:uuid, SecureRandom.uuid)
      jti = opts.fetch(:jti, SecureRandom.uuid)
      async = opts.fetch(:async, false)
      body = {
        device_id: @messaging.device_id,
        typ: 'authentication_req',
        aud: @client.self_url,
        iss: @jwt.id,
        sub: user_id,
        iat: Selfid::Time.now.strftime('%FT%TZ'),
        exp: (Selfid::Time.now + 3600).strftime('%FT%TZ'),
        cid: uuid,
        jti: jti,
      }
      body = @jwt.prepare(body)
      return body if !opts.fetch(:request, true)

      if block_given?
        @messaging.uuid_observer[uuid] = Proc.new do |res|
          auth = authenticated?(res.input)
          block.call(auth)
        end
        # when a block is given the request will always be asynchronous.
        async = true
      end

      Selfid.logger.info "authenticating uuid #{uuid}"
      if async
        @client.auth(body)
        return uuid
      end
      resp = @messaging.wait_for uuid do
        @client.auth(body)
      end
      authenticated?(resp.input)
    end

    # Gets an identity details
    #
    # @param id [string] identity SelfID
    def identity(id)
      @client.identity(id)
    end

    # Gets an app defails
    #
    # @param id [string] app SelfID
    def app(id)
      @client.app(id)
    end

    # Requests information to an entity
    #
    # @param id [string] selfID to be requested
    # @param fields [array] list of fields to be requested
    # @param type [symbol] you can define if you want to request this
    # =>  information on a sync or an async way
    # @option opts [String] :intermediary the intermediary selfid to be used.
    def request_information(id, fields, opts = {}, &block)
      async = opts.include?(:type) && (opts[:type] == :async)
      m = Selfid::Messages::IdentityInfoReq.new(@messaging)
      m.id = SecureRandom.uuid
      m.from = @jwt.id
      m.to = id
      m.fields = prepare_facts(fields)
      m.id = opts[:cid] if opts.include?(:cid)
      m.intermediary = opts[:intermediary] if opts.include?(:intermediary)
      m.description = opts[:description] if opts.include?(:description)
      return @jwt.prepare(m.body) if !opts.fetch(:request, true)

      devices = if opts.include?(:intermediary)
                  @client.devices(opts[:intermediary])
                else
                  @client.devices(id)
                end
      device = devices.first
      m.to_device = device

      if block_given?
        @messaging.uuid_observer[m.id] = block
        # when a block is given the request will always be asynchronous.
        async = true
      end

      return m.send_message if async

      m.request
    end

    # Adds an observer for a message type
    #
    # @param type [string] message type (ex: Selfid::Messages::AuthenticationResp.MSG_TYPE
    # @param block [block] observer to be executed.
    def on_message(type, &block)
      if type == Selfid::Messages::AuthenticationResp::MSG_TYPE
        @messaging.type_observer[type] = Proc.new do |res|
          auth = authenticated?(res.input)
          block.call(auth)
        end

      else
        @messaging.type_observer[type] = block
      end
    end

    # Permits incomming messages from the given identity.
    #
    # @param type [id] identity to be allowed
    def permit_connection(id)
      @acl.allow id
    end

    # Lists allowed connections.
    def allowed_connections
      @acl.list
    end

    # Revokes incomming messages from the given identity.
    #
    # @param type [id] identity to be denied
    def revoke_connection(id)
      @acl.deny id
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

    def prepare_facts(fields)
      fs = []
      fields.each do |f|
        if f.is_a?(Hash)
          fs << f
        else
          fs << {
            source: "user-specified",
            field: f,
          }
        end
      end
      fs
    end

    def valid_payload(response)
      jws = @jwt.parse(response)
      return nil unless jws.include? :payload

      payload = JSON.parse(@jwt.decode(jws[:payload]), symbolize_names: true)

      return nil if payload.nil?

      identity = identity(payload[:sub])
      return nil if identity.nil?

      identity[:public_keys].each do |key|
        return payload if @jwt.verify(jws, key[:key])
      end
      nil
    rescue StandardError => e
      uuid = ""
      uuid = payload[:cid] unless payload.nil?
      Selfid.logger.error "error checking authentication for #{uuid} : #{e.message}"
      nil
    end
  end
end
