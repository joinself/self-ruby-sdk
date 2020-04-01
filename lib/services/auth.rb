# frozen_string_literal: true

module Selfid
  module Services
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
        resp = @app.messaging.client.wait_for uuid do
          @app.client.auth(body)
        end
        authenticated?(resp.input)
      end

      def generate_qr(opts = {})
        opts[:request] = false
        selfid = opts.fetch(:selfid, "-")
        req = request(selfid, opts)
        ::RQRCode::QRCode.new(req, level: 'l')
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
  end
end
