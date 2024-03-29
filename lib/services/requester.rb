# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

# Namespace for classes and modules that handle SelfSDK gem
module SelfSDK
  # Namespace for classes and modules that handle selfsdk-gem public ui
  module Services
    # Self provides this self-hosted verified intermediary.
    DEFAULT_INTERMEDIARY = "self_intermediary"
    # Input class to handle fact requests on self network.
    class Requester
      attr_reader :messaging

      # Creates a new facts service.
      # Facts service mainly manages fact requests against self users wanting
      # to share their verified facts with your app.
      #
      # @param messaging [SelfSDK::Messaging] messaging object.
      # @param client [SelfSDK::Client] http client object.
      #
      # @return [SelfSDK::Services::Facts] facts service.
      def initialize(messaging, client)
        @messaging = messaging.client
        @messaging_service = messaging
        @client = client
      end

      # Sends a fact request to the specified selfid.
      # An fact request allows your app to access trusted facts of your user with its
      # permission.
      #
      # @overload request(selfid, facts, opts = {}, &block)
      #  @param selfid [string] the receiver of the authentication request.
      #  @param [Hash] opts the options to authenticate.
      #  @option opts [String] :cid The unique identifier of the authentication request.
      # @yield [request] Invokes the given block when a response is received.
      #  @return [Object] SelfSDK:::Messages::FactRequest
      #
      # @overload request(selfid, facts, opts = {})
      #  @param selfid [string] the receiver of the authentication request.
      #  @param [Hash] opts the options to authenticate.
      #  @option opts [String] :cid The unique identifier of the authentication request.
      #  @option opts [Integer] :exp_timeout timeout in seconds to expire the request.
      #  @option opts [Integer] :allowed_for number of seconds for enabling recurrent requests.
      #  @option opts [Boolean] :auth allows displaying the request as anuthentication request with facts.
      #  @return [Object] SelfSDK:::Messages::FactRequest
      def request(selfid, facts, opts = {}, &block)
        SelfSDK.logger.info "authenticating #{selfid}"
        rq = opts.fetch(:request, true)

        req = SelfSDK::Messages::FactRequest.new(@messaging)
        req.populate(selfid, prepare_facts(facts), opts)

        body = @client.jwt.prepare(req.body)
        return body unless rq

        # when a block is given the request will always be asynchronous.
        if block_given?
          @messaging.set_observer(req, timeout: req.exp_timeout, &block)
          return req.send_message
        end

        if opts[:async] == true
          return req.send_message
        end

        # Otherwise the request is synchronous
        req.request
      end

      # Sends a request through an intermediary.
      # An intermediary is an entity trusted by the user and acting as a proxy between you
      # and the recipient of your fact request.
      # Intermediaries usually do not provide the original user facts, but they create its
      # own assertions based on your request and the user's facts.
      #
      #  @param selfid [string] the receiver of the authentication request.
      #  @param [Hash] opts the options to authenticate.
      #  @option opts [String] intermediary an intermediary identity to be used.
      #  @return [Object] SelfSDK:::Messages::FactRequest
      def request_via_intermediary(selfid, facts, opts = {}, &block)
        opts[:intermediary] = opts.fetch(:intermediary, DEFAULT_INTERMEDIARY)
        request(selfid, facts, opts, &block)
      end

      # Adds an observer for a fact response
      # Whenever you receive a fact response registered observers will receive a notification.
      #
      #  @yield [request] Invokes the block with a fact response message.
      def subscribe(auth, &block)
        if auth == true
          @auth_subscription = block
        else
          @fact_subscription = block
        end

        @messaging.subscribe :fact_response do |res|
          if res.auth_response?
            @auth_subscription&.call(res)
          else
            @fact_subscription&.call(res)
          end
        end
      end

      # Generates a QR code so users can send facts to your app.
      #
      # @param facts [Array] a list of facts to be requested.
      # @option opts [String] :cid The unique identifier of the authentication request.
      # @option opts [String] :options Options you want to share with the identity.
      #
      # @return [String, String] conversation id or encoded body.
      def generate_qr(facts, opts = {})
        opts[:request] = false
        selfid = opts.fetch(:selfid, "-")
        req = request(selfid, facts, opts)
        ::RQRCode::QRCode.new(req, level: 'l')
      end

      # Generates a deep link to authenticate with self app.
      #
      # @param facts [Array] a list of facts to be requested.
      # @param callback [String] the callback identifier you'll be redirected to if the app is not installed.
      # @option opts [String] :selfid the user selfid you want to authenticate.
      # @option opts [String] :cid The unique identifier of the authentication request.
      #
      # @return [String, String] conversation id or encoded body.
      def generate_deep_link(facts, callback, opts = {})
        opts[:request] = false
        selfid = opts.fetch(:selfid, "-")

        body = @client.jwt.encode(request(selfid, facts, opts))
        @client.jwt.build_dynamic_link(body, @client.env, callback)
      end

      private

      # As request facts can accept an array of strings this populates with necessary
      # structure this short fact definitions.
      #
      # @param facts [Array] an array of strings or hashes.
      # @return [Array] a list of hashed facts.
      def prepare_facts(facts)
        fs = []
        facts.each do |f|
          fact = if f.is_a?(Hash)
                   f
                 else
                   { fact: f }
                 end
          validate_fact!(fact) unless fact.key?('issuers')
          fs << fact
        end
        fs
      end

      def validate_fact!(f)
        errInvalidFactToSource = 'provided source does not support given fact'
        errInvalidSource = 'provided fact does not specify a valid source'
        fact_name = f[:fact].to_s

        raise 'provided fact does not specify a name' if fact_name.empty?
        return unless f.has_key? :sources
        return if f.has_key? :issuers # skip the validation if is a custom fact

        raise "invalid fact '#{fact_name}'" unless @messaging.source.core_fact?(fact_name)

        spec = @messaging.source.sources
        f[:sources].each do |s|
          raise errInvalidSource unless spec.key?(s.to_s)
          raise errInvalidFactToSource unless spec[s.to_s].include? fact_name.to_s
        end
      end
    end
  end
end
