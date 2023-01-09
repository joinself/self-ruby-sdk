# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true
require 'open-uri'

module SelfSDK
  module Chat
    class FileObject
      attr_accessor :name, :link, :mime, :content, :key, :nonce, :ciphertext

      def initialize(token, url)
        @token = token
        @url = url
      end

      def build_from_data(name, data, mime, opts = {})
        @key = SelfCrypto::Util.aead_xchacha20poly1305_ietf_keygen
        @nonce = SelfCrypto::Util.aead_xchacha20poly1305_ietf_nonce
        @content = data
        @name = name
        @mime = mime

        # encrypt the object
        @ciphertext = SelfCrypto::Util.aead_xchacha20poly1305_ietf_encrypt(@key, @nonce, @content)

        # Upload
        remote_object = upload(ciphertext)
        public_url = opts[:public_url] || @url
        @link = "#{public_url}/v1/objects/#{remote_object["id"]}"
        @expires = remote_object["expires"]

        self
      end

      # Incoming objects
      def build_from_object(input)
        # Download from CDN
        ciphertext = ""
        link = input[:link]
        5.times do
          begin
            ciphertext = URI.open(link, "Authorization" => "Bearer #{@token}").read
            break
          rescue => e
            SelfSDK.logger.info "error fetching #{input[:link]} : #{e.message}"
            link = link.replace("localhost:8080", "api:8080")
            sleep 1
          end
        end

        if ciphertext.empty?
          SelfSDK.logger.warn "unable to process incoming object"
          return
        end

        @content = ciphertext
        @key = nil
        @nonce = nil
        if input.key?(:key) && !input[:key].empty?
          # Decrypt
          composed_key = extract_key(input[:key])
          @key =   composed_key[:key]
          @nonce = composed_key[:nonce]

          @content = SelfCrypto::Util.aead_xchacha20poly1305_ietf_decrypt(@key, @nonce, ciphertext)
        end

        @name =  input[:name]
        @link =  input[:link]
        @mime =  input[:mime]
        @expires = input[:expires]

        self
      end

      def to_payload
        {
          name: @name,
          link: @link,
          key: build_key(@key, @nonce),
          mime: @mime,
          expires: @expires
        }
      end

      def save(path)
        File.open(path, 'wb') { |file| file.write(@content) }
      end

      private

      def upload(ciphertext)
        uri = URI.parse("#{@url}/v1/objects")
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true if uri.scheme == "https"
        req = Net::HTTP::Post.new(uri.path)
        req["Authorization"] = "Bearer #{@token}"
        req.body = ciphertext.force_encoding("UTF-8")
        res = https.request(req)
        JSON.parse(res.body)
      end

      def build_key(key, nonce)
        Base64.urlsafe_encode64("#{key}#{nonce}", padding: false)
      end

      def extract_key(shareable_key)
        k = Base64.urlsafe_decode64(shareable_key)
        { key: k[0, 32],
          nonce: k[32, (k.length - 32)] }
      end
    end
  end
end