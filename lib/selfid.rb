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

# Namespace for classes and modules that handle Self interactions.
module Selfid
  # Abstract base class for CLI utilities. Provides some helper methods for
  # the option parser
  #
  # @attr_reader [Types] app_id the identifier of the current app.
  # @attr_reader [Types] app_key the api key for the current app.
  class App
    attr_reader :app_id, :app_key, :client, :jwt
    attr_accessor :messaging

    # Initializes a Selfid App
    #
    # @param app_id [string] the app id.
    # @param app_key [string] the app api key provided by developer portal.
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :self_url The self provider url.
    def initialize(app_id, app_key, opts = {})
      @jwt = Selfid::Jwt.new(app_id, app_key)

      url = opts.fetch(:self_url, "https://api.review.selfid.net")
      Selfid.logger.info "client setup with #{url}"
      @client = RestClient.new(url, @jwt.auth_token)

      @public_url = opts.fetch(:public_url, url)
      @public_url = url if @public_url.nil?
      @public_url = url if @public_url.empty?

      messaging_url = opts.fetch(:messaging_url, "wss://messaging.review.selfid.net/v1/messaging")
      @messaging = MessagingClient.new(messaging_url, @jwt, @client) unless messaging_url.nil?
    end

    # Sends an authentication request to the specified user_id.
    #
    # @param user_id [string] the receiver of the authentication request.
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :uuid The unique identifier of the authentication request.
    # @option opts [String] :callback the callback url where self will send authentication response.
    def authenticate(user_id, opts = {})
      Selfid.logger.info "authenticating #{user_id}"
      uuid = opts.fetch(:uuid, SecureRandom.uuid)
      jti = opts.fetch(:jti, SecureRandom.uuid)
      callback = opts.fetch(:callback, "")
      body = {
        device_id: @messaging.device_id,
        typ: 'authentication_req',
        aud: @public_url,
        iss: @jwt.id,
        sub: user_id,
        iat: Selfid::Time.now.strftime('%FT%TZ'),
        exp: (Selfid::Time.now + 3600).strftime('%FT%TZ'),
        cid: uuid,
        jti: jti,
      }
      body[:callback] = callback if !callback.empty?
      body = @jwt.prepare(body)
      return body if !opts.fetch(:request, true)

      Selfid.logger.info "authenticating uuid #{uuid}"
      if !callback.empty?
        @client.auth(body)
        return uuid
      end
      resp = @messaging.wait_for uuid do
        @client.auth(body)
      end
      authenticated?(resp.input)
    end

    # Checks if the given input is an accepted authentication request.
    #
    # @param response [string] the response to an authentication request from self-api.
    # @return [Hash] Details response.
    #   * :accepted [Boolean] a bool describing if authentication is accepted or not.
    #   * :uuid [String] the request identifier.
    def authenticated?(response)
      Authenticated.new(valid_payload(response))
    end

    # Gets identity defails
    def identity(id)
      @client.identity(id)
    end

    # Allows authenticated user to receive incoming messages from the given id
    #
    # @params id [string] SelfID to be allowed
    def connect(id)
      Selfid.logger.info "Setting ACL for #{id}"
      @messaging.connect(@jwt.prepare(
                           iss: @jwt.id,
                           acl_source: id,
                           acl_exp: (Selfid::Time.now + 360_000).to_datetime.rfc3339
                         ))
    end

    # Gets a list of received messages
    def inbox
      @messaging.inbox
    end

    def clear_inbox
      @messaging.inbox = {}
    end

    # Will stop listening for messages
    def stop
      @messaging.stop
    end

    def parse(input)
      Selfid::Messages.parse(input, @messaging)
    end

    # Requests information to an entity
    #
    # @param id [string] selfID to be requested
    # @param fields [array] list of fields to be requested
    # @param type [symbol] you can define if you want to request this
    # =>  information on a sync or an async way
    def request_information(id, fields, opts = {})
      m = Selfid::Messages::IdentityInfoReq.new(@messaging)
      m.id = SecureRandom.uuid
      m.from = @jwt.id
      m.to = id
      m.fields = prepare_facts(fields)
      m.id = opts[:cid] if opts.include?(:cid)
      m.proxy = opts[:proxy] if opts.include?(:proxy)
      m.description = opts[:description] if opts.include?(:description)
      return @jwt.prepare(m.body) if !opts.fetch(:request, true)

      devices = if opts.include?(:proxy)
                  @client.devices(opts[:proxy])
                else
                  @client.devices(id)
                end
      device = devices.first
      m.to_device = device
      return m.send if opts.include?(:type) && (opts[:type] == :async)

      Selfid.logger.info "synchronously requesting information to #{id}:#{device}"
      m.request
    end

    private

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
