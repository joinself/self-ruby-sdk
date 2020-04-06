# frozen_string_literal: true

# Namespace for classes and modules that handle Selfid gem
module Selfid
  # Namespace for classes and modules that handle selfid-gem public ui
  module Services
    # Input class to handle authentication requests on self network.
    class Authentication
      # Creates a new authentication service.
      # Authentication service mainly manages authentication requests against self
      # users wanting to authenticate on your app.
      #
      # @param messaging [Selfid::Messaging] messaging object.
      # @param client [Selfid::Client] http client object.
      #
      # @return [Selfid::Services::Authentication] authentication service.
      def initialize(messaging, client)
        @messaging = messaging
        @client = client
      end

      # Sends an authentication request to the specified selfid.
      # An authentication requests allows your users to authenticate on your app using
      # a secure self app.
      #
      # @overload request(selfid, opts = {}, &block)
      #  @param [String] selfid the receiver of the authentication request.
      #  @param [Hash] opts the options to authenticate.
      #  @option opts [String] :cid The unique identifier of the authentication request.
      #  @option opts [String] :jti specify the jti to be used.
      #  @yield [request] Invokes the block with an authentication response for each result.
      #  @return [String, String] conversation id or encoded body.
      #
      # @overload request(selfid, opts = {})
      #  @param [String] selfid the receiver of the authentication request.
      #  @param [Hash] opts the options to authenticate.
      #  @option opts [String] :cid The unique identifier of the authentication request.
      #  @option opts [String] :jti specify the jti to be used.
      #  @return [String, String] conversation id or encoded body.
      def request(selfid, opts = {}, &block)
        Selfid.logger.info "authenticating #{selfid}"

        req = Selfid::Messages::AuthenticationReq.new(@messaging)
        req.populate(selfid, opts)

        body = @client.jwt.prepare(req.body)
        return body unless opts.fetch(:request, true)

        # when a block is given the request will always be asynchronous.
        if block_given?
          @messaging.set_observer(req.id, &block)
          return req.send_message
        end

        # Otherwise the request is synchronous
        req.request
      end

      # Generates a QR code so users can authenticate to your app.
      #
      # @option opts [String] :selfid the user selfid you want to authenticate.
      # @option opts [String] :jti specify the jti to be used.
      # @option opts [String] :uuid The unique identifier of the authentication request.
      #
      # @return [String, String] conversation id or encoded body.
      def generate_qr(opts = {})
        opts[:request] = false
        selfid = opts.fetch(:selfid, "-")
        req = request(selfid, opts)
        ::RQRCode::QRCode.new(req, level: 'l')
      end

      # Adds an observer for an authentication response
      def subscribe(&block)
        @messaging.subscribe Selfid::Messages::AuthenticationResp::MSG_TYPE do |res|
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

      # checks if a payload is valid or not.
      #
      # @param response [string] the response to an authentication request from self-api.
      def valid_payload(response)
        payload = @client.jwt.parse_payload(input)
        return if payload.nil?

        identity = @client.entity(payload[:sub])
        return nil if identity.nil?

        identity[:public_keys].each do |key|
          return payload if @client.jwt.verify(jws, key[:key])
        end
        nil
      rescue StandardError => e
        uuid = ""
        uuid = payload[:cid] unless payload.nil?
        Selfid.logger.error "error checking authentication for #{uuid} : #{e.message}"
        p e.backtrace
        nil
      end

      # Prepares an authentication payload to be sent to a user.
      #
      # @param selfid [string] the selfid of the user you want to send the auth request to.
      # @param cid [string] the conversation id to be used.
      def prepare_payload(selfid, cid)
        # TODO should this be moved to its own message/auth_req.rb?
        body = {
            typ: 'authentication_req',
            aud: @client.self_url,
            iss: @client.jwt.id,
            sub: selfid,
            iat: Selfid::Time.now.strftime('%FT%TZ'),
            exp: (Selfid::Time.now + 3600).strftime('%FT%TZ'),
            cid: cid,
            jti: SecureRandom.uuid,
            device_id: @messaging.device_id,
        }

        @client.jwt.prepare(body)
      end

      # Waits for the response of a specific conversation and executes a block
      #
      # @param cid [string] the conversation id to be used.
      def observe(cid, &block)
        @messaging.set_observer cid do |res|
          yield(authenticated?(res.input))
        end
      end
    end
  end
end
