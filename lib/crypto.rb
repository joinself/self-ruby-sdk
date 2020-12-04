# Copyright 2020 Self Group Ltd. All Rights Reserved.

require 'self_crypto'

module SelfSDK
  class Crypto
    def initialize(client, device, storage_folder, storage_key)
      @client = client
      @device = device
      @storage_key = storage_key
      @storage_folder = storage_folder

      if File.exist?(account_path)
        # 1a) if alice's account file exists load the pickle from the file
        @account = SelfCrypto::Account.from_pickle(File.read(account_path), @storage_key)
      else
        # 1b-i) if create a new account for alice if one doesn't exist already
        @account = SelfCrypto::Account.from_seed(@client.jwt.key)

        # 1b-ii) generate some keys for alice and publish them
        @account.gen_otk(100)

        # 1b-iii) convert those keys to json
        keys = @account.otk['curve25519'].map{|k,v| {id: k, key: v}}.to_json

        # 1b-iv) post those keys to POST /v1/identities/<selfid>/devices/1/pre_keys/
        @client.post("/v1/apps/#{@client.jwt.id}/devices/#{@device}/pre_keys", keys)

        # 1b-v) store the account to a file
        File.write(account_path, @account.to_pickle(storage_key))
      end
    end

    def encrypt(message, recipient, recipient_device)
      session_file_name = session_path(recipient, recipient_device)

      if File.exist?(session_file_name)
        # 2a) if bob's session file exists load the pickle from the file
        session_with_bob = SelfCrypto::Session.from_pickle(File.read(session_file_name), @storage_key)
      else
        # 2b-i) if you have not previously sent or recevied a message to/from bob,
        #       you must get his identity key from GET /v1/identities/bob/
        ed25519_identity_key = @client.device_public_key(recipient, recipient_device)

        # 2b-ii) get a one time key for bob
        res = @client.get("/v1/identities/#{recipient}/devices/#{recipient_device}/pre_keys")

        if res.code != 200
          Selfid.logger.error "identity response : #{res.body[:message]}"
          raise "could not get identity pre_keys"
        end

        one_time_key = JSON.parse(res.body)["key"]

        # 2b-iii) convert bobs ed25519 identity key to a curve25519 key
        curve25519_identity_key = SelfCrypto::Util.ed25519_pk_to_curve25519(ed25519_identity_key.raw_public_key)

        # 2b-iv) create the session with bob
        session_with_bob = @account.outbound_session(curve25519_identity_key, one_time_key)
      end

      # 3) create a group session and set the identity of the account youre using
      gs = SelfCrypto::GroupSession.new("#{@client.jwt.id}:#{@device}")

      # 4) add all recipients and their sessions
      gs.add_participant("#{recipient}:#{recipient_device}", session_with_bob)

      # 5) encrypt a message
      ct = gs.encrypt(message).to_s

      # 6) store the session to a file
      File.write(session_file_name, session_with_bob.to_pickle(@storage_key))

      ct
    end

    def decrypt(message, sender, sender_device)
      session_file_name = session_path(sender, sender_device)

      if File.exist?(session_file_name)
        # 7a) if carol's session file exists load the pickle from the file
        session_with_bob = SelfCrypto::Session.from_pickle(File.read(session_file_name), @storage_key)
      else
        # 7b-i) if you have not previously sent or received a message to/from bob,
        #       you should extract the initial message from the group message intended
        #       for your account id.
        m = SelfCrypto::GroupMessage.new(message.to_s).get_message("#{@client.jwt.id}:#{@device}")

        # 7b-ii) use the initial message to create a session for bob or carol
        session_with_bob = @account.inbound_session(m)
      end

      # 8) create a group session and set the identity of the account you're using
      gs = SelfCrypto::GroupSession.new("#{@client.jwt.id}:#{@device}")

      # 9) add all recipients and their sessions
      gs.add_participant("#{sender}:#{sender_device}", session_with_bob)

      # 10) decrypt the message ciphertext
      pt = gs.decrypt("#{sender}:#{sender_device}", message).to_s

      # 11) store the session to a file
      File.write(session_file_name, session_with_bob.to_pickle(@storage_key))

      pt
    end

    private

    def account_path
      "#{@storage_folder}/account.pickle"
    end

    def session_path(selfid, device)
      "#{@storage_folder}/#{selfid}:#{device}-session.pickle"
    end
  end
end
