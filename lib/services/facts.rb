# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true
require_relative '../messages/fact_issue.rb'

# Namespace for classes and modules that handle SelfSDK gem
module SelfSDK
  # Namespace for classes and modules that handle selfsdk-gem public ui
  module Services
    # Self provides this self-hosted verified intermediary.
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
      def initialize(requester)
        @requester = requester
      end

      # Sends a fact request to the specified selfid.
      # An fact request allows your app to access trusted facts of your user with its
      # permission.
      #
      # @overload request(selfid, facts, opts = {}, &block)
      #  @param selfid [string] the receiver of the fact request.
      #  @param facts [Array] array of facts to be requested
      #  @param [Hash] opts the options to process the request.
      #  @option opts [String] :cid The unique identifier of the fact request.
      # @yield [request] Invokes the given block when a response is received.
      #  @return [Object] SelfSDK:::Messages::FactRequest
      #
      # @overload request(selfid, facts, opts = {})
      #  @param selfid [string] the receiver of the fact request.
      #  @param facts [Array] array of facts to be requested
      #  @param [Hash] opts the options to request.
      #  @option opts [String] :cid The unique identifier of the fact request.
      #  @option opts [Integer] :exp_timeout timeout in seconds to expire the request.
      #  @option opts [Integer] :allowed_for number of seconds for enabling recurrent requests.
      #  @return [Object] SelfSDK:::Messages::FactRequest
      def request(selfid, facts, opts = {}, &block)
        opts[:auth] = false # force auth to false as you have auth service to make auth requests
        @requester.request(selfid, facts, opts, &block)
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
        @requester.request_via_intermediary(selfid, facts, opts, &block)
      end

      # Adds an observer for a fact response
      # Whenever you receive a fact response registered observers will receive a notification.
      #
      #  @yield [request] Invokes the block with a fact response message.
      def subscribe(&block)
        @requester.subscribe(false, &block)
      end

      # Generates a QR code so users can send facts to your app.
      #
      # @param facts [Array] a list of facts to be requested.
      # @option opts [String] :cid The unique identifier of the authentication request.
      # @option opts [String] :options Options you want to share with the identity.
      #
      # @return [String, String] conversation id or encoded body.
      def generate_qr(facts, opts = {})
        opts[:auth] = false
        @requester.generate_qr(facts, opts)
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
        opts[:auth] = false
        @requester.generate_deep_link(facts, callback, opts)
      end

      # Issues a custom fact and sends it to the user.
      #
      # @param selfid [String] self identifier for the message recipient.
      # @param source [String] source where facts belong to.
      # @param facts [Array] facts to be sent to the user
      # @option opts [String] :viewers list of self identifiers for the user that will have access to this facts.
      def issue(selfid, source, facts, opts = {})
        SelfSDK.logger.info "issuing facts for #{selfid}"
        msg = SelfSDK::Messages::FactIssue.new(@requester.messaging)
        msg.populate(selfid, source, facts, opts)

        msg.send_message
      end
    end
  end
end