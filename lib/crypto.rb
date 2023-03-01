# Copyright 2020 Self Group Ltd. All Rights Reserved.

require 'self_crypto'

module SelfSDK
  class Crypto
    def initialize(client, device, storage_folder, storage_key)
      @client = client
      @device = device
      @storage_key = storage_key
      @storage_folder = "#{storage_folder}/#{@client.jwt.key_id}"
      @lock_strategy = true
      @mode = "r+"

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
        res = @client.post("/v1/apps/#{@client.jwt.id}/devices/#{@device}/pre_keys", keys)
        raise 'unable to push prekeys, please try in a few minutes' if res.code != 200

        # 1b-v) store the account to a file
        FileUtils.mkdir_p(@storage_folder)
        File.write(account_path, @account.to_pickle(storage_key))
      end
    end

    def encrypt(message, recipients)
      ::SelfSDK.logger.debug('- [crypto] encrypting a message')

      # create a group session and set the identity of the account youre using
      ::SelfSDK.logger.debug('- [crypto] create a group session and set the identity of the account youre using')
      gs = SelfCrypto::GroupSession.new("#{@client.jwt.id}:#{@device}")

      sessions = {}
      locks = {}
      ::SelfSDK.logger.debug('- [crypto] managing sessions with all recipients')

      recipients.each do |r|
        f = nil
        next if r[:id] == @client.jwt.id && r[:device_id] == @device

        session_file_name = session_path(r[:id], r[:device_id])
        session_with_bob = nil

        begin
          if File.exist?(session_file_name)
            # Lock the session file
            locks[session_file_name] = File.open(session_file_name, @mode)
            locks[session_file_name].flock(File::LOCK_EX)
          end
          session_with_bob = get_outbound_session_with_bob(locks[session_file_name], r[:id], r[:device_id])
        rescue => e
          ::SelfSDK.logger.warn("- [crypto]   there is a problem adding group participant #{r[:id]}:#{r[:device_id]}, skipping...")
          ::SelfSDK.logger.warn("- [crypto] #{e}")
          next
        end

        ::SelfSDK.logger.debug("- [crypto]   adding group participant #{r[:id]}:#{r[:device_id]}")
        gs.add_participant("#{r[:id]}:#{r[:device_id]}", session_with_bob)
        sessions[session_file_name] = session_with_bob
      end

      # 5) encrypt a message
      ::SelfSDK.logger.debug("- [crypto] group encrypting message")
      ct = gs.encrypt(message).to_s

      # 6) store the session to a file
      ::SelfSDK.logger.debug("- [crypto] storing sessions")
      sessions.each do |session_file_name, session_with_bob|
        pickle = session_with_bob.to_pickle(@storage_key)
        if locks[session_file_name]
          locks[session_file_name].rewind
          locks[session_file_name].write(pickle)
          locks[session_file_name].truncate(locks[session_file_name].pos)
        else
          File.write(session_file_name, pickle)
        end
      end

      ct
    ensure
      locks.each do |session_file_name, lock|
        # Unlock the file
        if lock
          lock.flock(File::LOCK_UN)
        end
      end
    end

    def decrypt(message, sender, sender_device)
      f = nil
      ::SelfSDK.logger.debug("- [crypto] decrypting a message")
      session_file_name = session_path(sender, sender_device)

      if File.exist?(session_file_name)
        # Lock the session file
        f = File.open(session_file_name, @mode)
        f.flock(File::LOCK_EX)
      end

      ::SelfSDK.logger.debug("- [crypto] loading sessions")
      session_with_bob = get_inbound_session_with_bob(f, message)

      # 8) create a group session and set the identity of the account you're using
      ::SelfSDK.logger.debug("- [crypto] create a group session and set the identity of the account #{@client.jwt.id}:#{@device}")
      gs = SelfCrypto::GroupSession.new("#{@client.jwt.id}:#{@device}")

      # 9) add all recipients and their sessions
      ::SelfSDK.logger.debug("- [crypto] add all recipients and their sessions #{@sender}:#{@sender_device}")
      gs.add_participant("#{sender}:#{sender_device}", session_with_bob)

      # 10) decrypt the message ciphertext
      ::SelfSDK.logger.debug("- [crypto] decrypt the message ciphertext")
      pt = gs.decrypt("#{sender}:#{sender_device}", message).to_s

      # 11) store the session to a file
      ::SelfSDK.logger.debug("- [crypto] store the session to a file")

      pickle = session_with_bob.to_pickle(@storage_key)
      if !f.nil?
        f.rewind
        f.write(pickle)
        f.truncate(f.pos)
      else
        File.write(session_file_name, pickle)
      end

      pt
    ensure
      # Unlock the session file
      f&.flock(File::LOCK_UN)
      f&.close
    end

    private

    def account_path
      "#{@storage_folder}/account.pickle"
    end

    def session_path(selfid, device)
      "#{@storage_folder}/#{selfid}:#{device}-session.pickle"
    end

    def get_outbound_session_with_bob(f, recipient, recipient_device)
      if !f.nil?
        pickle = f.read
        # 2a) if bob's session file exists load the pickle from the file
        session_with_bob = SelfCrypto::Session.from_pickle(pickle, @storage_key)
      else
        # 2b-i) if you have not previously sent or recevied a message to/from bob,
        #       you must get his identity key from GET /v1/identities/bob/
        ed25519_identity_key = @client.device_public_key(recipient, recipient_device)

        # 2b-ii) get a one time key for bob
        res = @client.get("/v1/identities/#{recipient}/devices/#{recipient_device}/pre_keys")

        if res.code != 200
          b = JSON.parse(res.body)
          ::SelfSDK.logger.error "- [crypto] identity response : #{b['message']}"
          raise "could not get identity pre_keys"
        end

        one_time_key = JSON.parse(res.body)["key"]

        # 2b-iii) convert bobs ed25519 identity key to a curve25519 key
        curve25519_identity_key = SelfCrypto::Util.ed25519_pk_to_curve25519(ed25519_identity_key.raw_public_key)

        # 2b-iv) create the session with bob
        session_with_bob = @account.outbound_session(curve25519_identity_key, one_time_key)
      end

      session_with_bob
    end

    def get_inbound_session_with_bob(f, message)
      if !f.nil?
        pickle = f.read
        # 7a) if carol's session file exists load the pickle from the file
        session_with_bob = SelfCrypto::Session.from_pickle(pickle, @storage_key)
      end

      # 7b-i) if you have not previously sent or received a message to/from bob,
      #       you should extract the initial message from the group message intended
      #       for your account id.
      m = SelfCrypto::GroupMessage.new(message.to_s).get_message("#{@client.jwt.id}:#{@device}")

      # if there is no session, create one
      # if there is an existing session and we are sent a one time key message, check
      # if it belongs to this current session and create a new inbound session if it doesn't
      if session_with_bob.nil? || m.instance_of?(SelfCrypto::PreKeyMessage) && !session_with_bob.will_receive?(m)
        # 7b-ii) use the initial message to create a session for bob or carol
        session_with_bob = @account.inbound_session(m)

        # 7b-iii) remove the session's prekey from the account
        @account.remove_one_time_keys(session_with_bob)

        current_one_time_keys = @account.otk['curve25519']

        # 7b-iv) if the number of remaining prekeys is below a certain threshold, publish new keys
        if current_one_time_keys.length < 10
          @account.gen_otk(100)

          keys = Array.new

          @account.otk['curve25519'].each do |k,v|
            keys.push({id: k, key: v}) if current_one_time_keys[k].nil?
          end

          res = @client.post("/v1/apps/#{@client.jwt.id}/devices/#{@device}/pre_keys", keys.to_json)
          raise 'unable to push prekeys, please try in a few minutes' if res.code != 200
        end

        File.write(account_path, @account.to_pickle(@storage_key))
      end

      session_with_bob
    end

  end
end
