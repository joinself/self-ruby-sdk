# frozen_string_literal: true

module Selfid
  module Services
    class Facts
      def initialize(app)
        @app = app
      end

      # Request fact to an identity
      #
      # @param id [string] selfID to be requested
      # @param facts [array] list of facts to be requested
      # @option opts [String] :intermediary the intermediary selfid to be used.
      # @option opts [String] :type you can define if you want to request this information on a sync or an async way
      def request(id, facts, opts = {}, &block)
        async = opts.include?(:type) && (opts[:type] == :async)
        m = Selfid::Messages::IdentityInfoReq.new(@app.messaging.client)
        m.id = SecureRandom.uuid
        m.from = @app.jwt.id
        m.to = id
        m.facts = prepare_facts(facts)
        m.id = opts[:cid] if opts.include?(:cid)
        m.intermediary = opts[:intermediary] if opts.include?(:intermediary)
        m.description = opts[:description] if opts.include?(:description)
        return @app.jwt.prepare(m.body) if !opts.fetch(:request, true)

        devices = if opts.include?(:intermediary)
                    @app.identity.devices(opts[:intermediary])
                  else
                    @app.identity.devices(id)
                  end
        device = devices.first
        m.to_device = device

        if block_given?
          @app.messaging.set_observer(m.id, &block)
          # when a block is given the request will always be asynchronous.
          async = true
        end

        return m.send_message if async

        m.request
      end

      # Adds an observer for an fact response
      def subscribe(&block)
        @app.messaging.subscribe(Selfid::Messages::IdentityInfoResp::MSG_TYPE, &block)
      end

      def generate_qr(facts)
        req = request("-", facts, request: false)
        ::RQRCode::QRCode.new(req, level: 'l')
      end

      private

      # fills facts with default values
      def prepare_facts(fields)
        fs = []
        fields.each do |f|
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