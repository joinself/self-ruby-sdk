# frozen_string_literal: true

# Namespace for classes and modules that handle SelfSDK gem
module SelfSDK
  # Namespace for classes and modules that handle selfsdk-gem public ui
  module Services
    # Input class to handle authentication requests on self network.
    class Authentication
      # Creates a new authentication service.
      # Authentication service mainly manages authentication requests against self
      # users wanting to authenticate on your app.
      #
      # @param messaging [SelfSDK::Messaging] messaging object.
      # @param client [SelfSDK::Client] http client object.
      #
      # @return [SelfSDK::Services::Authentication] authentication service.
      def initialize(messaging, client)
        @messaging = messaging.client
        @messaging_service = messaging
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
      #  @yield [request] Invokes the block with an authentication response for each result.
      #  @return [String, String] conversation id or encoded body.
      #
      # @overload request(selfid, opts = {})
      #  @param [String] selfid the receiver of the authentication request.
      #  @param [Hash] opts the options to authenticate.
      #  @option [Boolean] :async if the request is asynchronous.
      #  @option opts [String] :cid The unique identifier of the authentication request.
      #  @return [String, String] conversation id or encoded body.
      def request(selfid, opts = {}, &block)
        SelfSDK.logger.info "authenticating #{selfid}"
        if opts.fetch(:request, false)
          raise "You're not permitting connections from #{selfid}" unless @messaging_service.is_permitted?(selfid)
        end

        req = SelfSDK::Messages::AuthenticationReq.new(@messaging)
        req.populate(selfid, opts)

        body = @client.jwt.prepare(req.body)
        return body unless opts.fetch(:request, true)
        return req.send_message if opts.fetch(:async, false)

        # when a block is given the request will always be asynchronous.
        if block_given?
          @messaging.set_observer(req, timeout: req.exp_timeout, &block)
          return req.send_message
        end

        # Otherwise the request is synchronous
        req.request
      end

      # Generates a QR code so users can authenticate to your app.
      #
      # @option opts [String] :selfid the user selfid you want to authenticate.
      # @option opts [String] :cid The unique identifier of the authentication request.
      #
      # @return [String, String] conversation id or encoded body.
      def generate_qr(opts = {})
        opts[:request] = false
        selfid = opts.fetch(:selfid, "-")
        req = request(selfid, opts)
        ::RQRCode::QRCode.new(req, level: 'l')
      end

      # Generates a deep link to authenticate with self app.
      #
      # @param callback [String] the url you'll be redirected if the app is not installed.
      # @option opts [String] :selfid the user selfid you want to authenticate.
      # @option opts [String] :cid The unique identifier of the authentication request.
      #
      # @return [String, String] conversation id or encoded body.
      def generate_deep_link(callback, opts = {})
        opts[:request] = false
        selfid = opts.fetch(:selfid, "-")
        body = @client.jwt.encode(request(selfid, opts))

        if @client.env.empty?
          return "https://joinself.page.link/?link=#{callback}%3Fqr=#{body}&apn=com.joinself.app"
        elsif @client.env == 'development'
          return "https://joinself.page.link/?link=#{callback}%3Fqr=#{body}&apn=com.joinself.app.dev"
        end
        "https://joinself.page.link/?link=#{callback}%3Fqr=#{body}&apn=com.joinself.app.#{@client.env}"
      end

      # Adds an observer for an authentication response
      def subscribe(&block)
        @messaging.subscribe :authentication_response do |res|
          valid_payload(res.input)
          yield(res)
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
        parse_payload(response)
      rescue StandardError => e
        SelfSDK.logger.error e
        uuid = ""
        uuid = response[:cid] unless response.nil?
        SelfSDK.logger.error "error checking authentication for #{uuid} : #{e.message}"
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
            typ: 'identities.authenticate.req',
            aud: @client.self_url,
            iss: @client.jwt.id,
            sub: selfid,
            iat: SelfSDK::Time.now.strftime('%FT%TZ'),
            exp: (SelfSDK::Time.now + 3600).strftime('%FT%TZ'),
            cid: cid,
            jti: SecureRandom.uuid,
            device_id: @messaging.device_id,
        }

        @client.jwt.prepare(body)
      end

      def parse_payload(response)
        jws = @client.jwt.parse(response)
        return unless jws.include? :payload

        payload = JSON.parse(@client.jwt.decode(jws[:payload]), symbolize_names: true)
        return if payload.nil?

        identity = @client.entity(payload[:sub])
        return if identity.nil?

        return payload
      end
    end
  end
end
