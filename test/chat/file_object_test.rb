# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true
require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'

require 'webmock/minitest'

class FileObjectTest < Minitest::Test
  describe 'build_from_data' do
    let(:identity_key) { "xxxx" }

    describe "encrypt / decrypt" do
      let(:token) { "token" }
      let(:url) { "https://api.joinself.com" }

      let(:obj_name) { "name" }
      let(:data) { Base64.urlsafe_encode64("data", padding: false) }
      let(:mime) { "image/jpg" }
      let(:headers) {{ 'Accept'=>'*/*',
                       'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                       'Authorization'=>'Bearer token',
                       'User-Agent'=>'Ruby' }}

      def test_encrypt_decrypt
        # expect(client).to receive(:post).with("/v1/apps/#{jwt.id}/devices/#{device}/pre_keys", anything).and_return(post_resp)
        c = SelfSDK::Chat::FileObject.new(token, url)

        # encrypt
        stub_request(:post, "https://api.joinself.com/v1/objects").
          with(
            body: "\xFF\x82\xBB\x97\xD1\x91\xB8\x18\xBE\xBFP'\x85\x1Ekz\x1A\x1D\x16\xE3",
            headers: headers ).
          to_return(status: 200, body: "", headers: {})

        stub_request(:post, "https://api.joinself.com/v1/objects").
          with(
            headers: headers).
          to_return(status: 200, body: '{"id":"123456.png","expires":"111222333"}', headers: {})
        object = c.build_from_data(obj_name, data, mime)

        # decrypt
        stub_request(:get, "https://api.joinself.com/v1/objects/123456.png").
          with(
            headers: headers).
          to_return(status: 200, body: object.ciphertext, headers: {})
        output = c.build_from_object(object.to_payload).content

        assert_equal data, output
      end
    end


  end
end