# frozen_string_literal: true

require 'securerandom'
require "ed25519"
require 'json'
require 'net/http'
require_relative 'log'
require_relative 'jwt'
require_relative 'client'
require_relative 'messaging'

# Namespace for classes and modules that handle Self interactions.
module Selfid
  # Abstract base class for CLI utilities. Provides some helper methods for
  # the option parser
  #
  # @attr_reader [Types] app_id the identifier of the current app.
  # @attr_reader [Types] app_key the api key for the current app.
  class App
    attr_reader :app_id, :app_key, :client, :jwt

    # Initializes a Selfid App
    #
    # @param app_id [string] the app id.
    # @param app_key [string] the app api key provided by developer portal.
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :self_url The self provider url.
    def initialize(app_id, app_key, opts = {})
      @jwt = Selfid::Jwt.new(app_id, app_key)

      url = opts.fetch(:self_url, "https://api.selfid.net")
      Selfid.logger.info "client setup with #{url}"
      @client = RestClient.new(url, @jwt.auth_token)

      messaging_url = opts.fetch(:messaging_url, "wss://messaging.review.selfid.net/v1/messaging")
      @messaging = MessagingClient.new(messaging_url, @jwt, @client)
    end

    # Sends an authentication request to the specified user_id.
    #
    # @param user_id [string] the receiver of the authentication request.
    # @param callback_url [string] the callback url where self will send authentication response.
    # @param [Hash] opts the options to authenticate.
    # @option opts [String] :uuid The unique identifier of the authentication request.
    def authenticate(user_id, callback_url, opts = {})
      Selfid.logger.info "authenticating #{user_id}"
      uuid = opts.fetch(:uuid, SecureRandom.uuid)
      @client.auth(@jwt.prepare({
        iss: callback_url,
        aud: @client.self_url,
        isi: @jwt.id,
        sub: user_id,
        iat: Time.now.utc.strftime('%FT%TZ'),
        exp: (Time.now.utc + 3600).strftime('%FT%TZ'),
        jti: uuid,
      }))
      Selfid.logger.info "authentication uuid #{uuid}"
      uuid
    end

    # Checks if the given input is an accepted authentication request.
    #
    # @param response [string] the response to an authentication request from self-api.
    # @return [Hash] Details response.
    #   * :accepted [Boolean] a bool describing if authentication is accepted or not.
    #   * :uuid [String] the request identifier.
    def authenticated?(response)
      res = { accepted: false }

      payload = valid_payload(response)
      return res if payload.nil?

      { uuid: payload[:jti],
        selfid: payload[:sub],
        accepted: (payload[:status] == "accepted") }
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
      @messaging.connect(@jwt.prepare({
        iss: @jwt.id,
        acl_source: id,
        acl_exp: (Time.now.utc + 360000).to_datetime.rfc3339
      }))
    end

    # Gets a list of received messages
    def inbox
      @messaging.inbox.values
    end

    # Will stop listening for messages
    def stop
      @messaging.stop
    end

    # Requests information to an entity
    #
    # @param id [string] selfID to be requested
    # @param fields [array] list of fields to be requested
    # @param type [symbol] you can define if you want to request this
    # =>  information on a sync or an async way
    def request_information(id, fields, type: :sync)
      devices = @client.devices(id)
      device = devices.first

      m = Selfid::Messages::IdentityInfoReq.new(@messaging)
      m.id = SecureRandom.uuid
      m.from = @jwt.id
      m.to = id
      m.to_device = device
      m.fields = fields

      return m.send if type == :sync
      Selfid.logger.info "asynchronously requesting information to #{id}:#{device}"
      m.send_async
    end

    private

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
        uuid = payload[:jti] unless payload.nil?
        Selfid.logger.error "error checking authentication for #{uuid} : #{e.message}"
        nil
      end


  end
end
