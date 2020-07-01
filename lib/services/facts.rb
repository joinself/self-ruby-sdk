# frozen_string_literal: true

# Namespace for classes and modules that handle Selfid gem
module Selfid
  # Namespace for classes and modules that handle selfid-gem public ui
  module Services
    # Self provides this self-hosted verified intermediary.
    DEFAULT_INTERMEDIARY = "self_intermediary"
    # Input class to handle authentication requests on self network.
    class Facts
      # Creates a new facts service.
      # Facts service mainly manages fact requests against self users wanting
      # to share their verified facts with your app.
      #
      # @param messaging [Selfid::Messaging] messaging object.
      # @param client [Selfid::Client] http client object.
      #
      # @return [Selfid::Services::Facts] facts service.
      def initialize(messaging, client)
        @messaging = messaging
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
      #  @yield [request] Invokes the block with a street name for each result.
      #  @return [Object] Selfid:::Messages::FactRequest
      #
      # @overload request(selfid, facts, opts = {})
      #  @param selfid [string] the receiver of the authentication request.
      #  @param [Hash] opts the options to authenticate.
      #  @option opts [String] :cid The unique identifier of the authentication request.
      #  @option opts [Integer] :exp_timeout timeout in seconds to expire the request.
      #  @return [Object] Selfid:::Messages::FactRequest
      def request(selfid, facts, opts = {}, &block)
        Selfid.logger.info "authenticating #{selfid}"

        req = Selfid::Messages::FactRequest.new(@messaging)
        req.populate(selfid, prepare_facts(facts), opts)

        body = @client.jwt.prepare(req.body)
        return body unless opts.fetch(:request, true)

        # when a block is given the request will always be asynchronous.
        if block_given?
          @messaging.set_observer(req, timeout: req.exp_timeout, &block)
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
      #  @return [Object] Selfid:::Messages::FactRequest
      def request_via_intermediary(selfid, facts, opts = {}, &block)
        opts[:intermediary] = opts.fetch(:intermediary, DEFAULT_INTERMEDIARY)
        request(selfid, facts, opts, &block)
      end

      # Adds an observer for a fact response
      # Whenever you receive a fact response registered observers will receive a notification.
      #
      #  @yield [request] Invokes the block with a fact response message.
      def subscribe(&block)
        @messaging.subscribe(:fact_response, &block)
      end

      # Generates a QR code so users can send facts to your app.
      #
      # @param facts [Array] a list of facts to be requested.
      # @option opts [String] :cid The unique identifier of the authentication request.
      # @option opts [String] :process_each_request In case you want this request to be used multiple times.
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
      # @param callback [String] the url you'll be redirected if the app is not installed.
      # @option opts [String] :selfid the user selfid you want to authenticate.
      # @option opts [String] :cid The unique identifier of the authentication request.
      #
      # @return [String, String] conversation id or encoded body.
      def generate_deep_link(facts, callback, opts = {})
        opts[:request] = false
        selfid = opts.fetch(:selfid, "-")
        body = @client.jwt.encode(request(selfid, facts, opts))

        if @client.env.empty?
          return "https://selfid.page.link/?link=#{callback}%3Fqr=#{body}&apn=net.selfid.app"
        elsif @client.env == 'development'
          return "https://selfid.page.link/?link=#{callback}%3Fqr=#{body}&apn=net.selfid.app.dev"
        end
        "https://selfid.page.link/?link=#{callback}%3Fqr=#{body}&apn=net.selfid.app.#{@client.env}"
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
end