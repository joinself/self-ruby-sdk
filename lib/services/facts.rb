# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

# Namespace for classes and modules that handle SelfSDK gem
module SelfSDK
  # Namespace for classes and modules that handle selfsdk-gem public ui
  module Services
    # Self provides this self-hosted verified intermediary.
    DEFAULT_INTERMEDIARY = "self_intermediary"
    # Input class to handle fact requests on self network.
    class Facts
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
        if rq
          raise "You're not permitting connections from #{selfid}" unless @messaging_service.is_permitted?(selfid)
        end

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
      def subscribe(&block)
        @messaging.subscribe(:fact_response, &block)
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
          return "https://links.joinself.com/?link=#{callback}%3Fqr=#{body}&apn=com.joinself.app"
        elsif @client.env == 'development'
          return "https://links.joinself.com/?link=#{callback}%3Fqr=#{body}&apn=com.joinself.app.dev"
        end
        "https://#{@client.env}.links.joinself.com/?link=#{callback}%3Fqr=#{body}&apn=com.joinself.app.#{@client.env}"
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
          # validate_fact!(fact)
          fs << fact
        end
        fs
      end

      def validate_fact!(f)
        errInvalidFactToSource = 'provided source does not support given fact'
        errInvalidSource = 'provided fact does not specify a valid source'

        raise 'provided fact does not specify a name' if f[:fact].empty?
        return unless f.has_key? :sources

        valid_sources = [SOURCE_USER_SPECIFIED,
                         SOURCE_PASSPORT,
                         SOURCE_DRIVING_LICENSE,
                         SOURCE_IDENTITY_CARD,
                         SOURCE_TWITTER,
                         SOURCE_LINKEDIN,
                         SOURCE_FACEBOK]
        fact_for_passport = [FACT_DOCUMENT_NUMBER,
                             FACT_SURNAME,
                             FACT_GIVEN_NAMES,
                             FACT_DATE_OF_BIRTH,
                             FACT_DATE_OF_EXPIRATION,
                             FACT_SEX,
                             FACT_NATIONALITY,
                             FACT_COUNTRY_OF_ISSUANCE]

        facts_for_dl = [FACT_DOCUMENT_NUMBER,
                        FACT_SURNAME,
                        FACT_GIVEN_NAMES,
                        FACT_DATE_OF_BIRTH,
                        FACT_DATE_OF_ISSUANCE,
                        FACT_DATE_OF_EXPIRATION,
                        FACT_ADDRESS, 
                        FACT_ISSUING_AUTHORITY,
                        FACT_PLACE_OF_BIRTH, 
                        FACT_COUNTRY_OF_ISSUANCE]

        facts_for_user = [FACT_DOCUMENT_NUMBER,
                          FACT_DISPLAY_NAME,
                          FACT_EMAIL,
                          FACT_PHONE]

        facts_for_twitter = [FACT_ACCOUNT_ID, FACT_NICKNAME]
        facts_for_linkedin = [FACT_ACCOUNT_ID, FACT_NICKNAME]
        facts_for_facebook = [FACT_ACCOUNT_ID, FACT_NICKNAME]
        facts_for_live = [FACT_SELFIE]

        f[:sources].each do |s|
          raise errInvalidSource unless valid_sources.include? s.to_s

          if s.to_s == SOURCE_PASSPORT || s.to_s == SOURCE_IDENTITY_CARD
            raise errInvalidFactToSource unless fact_for_passport.include? f[:fact]
          end

          if s.to_s == SOURCE_DRIVING_LICENSE
            raise errInvalidFactToSource unless facts_for_dl.include? f[:fact]
          end

          if s.to_s == SOURCE_USER_SPECIFIED
            raise errInvalidFactToSource unless facts_for_user.include? f[:fact].to_s
          end

          if s.to_s == SOURCE_TWITTER
            raise errInvalidFactToSource unless facts_for_twitter.include? f[:fact].to_s
          end

          if s.to_s == SOURCE_LINKEDIN
            raise errInvalidFactToSource unless facts_for_linkedin.include? f[:fact].to_s
          end

          if s.to_s == SOURCE_FACEBOOK
            raise errInvalidFactToSource unless facts_for_facebook.include? f[:fact].to_s
          end

          if s.to_s == SOURCE_LIVE
            raise errInvalidFactToSource unless facts_for_live.include? f[:fact].to_s
          end
        end
      end
    end
  end
end