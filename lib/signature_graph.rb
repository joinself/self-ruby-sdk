require 'base64'
require 'json'

module SelfSDK
  
  class Operation

    attr_reader :sequence, :previous, :timestamp, :actions, :signing_key, :jws

    def initialize(operation)
      @jws = JSON.parse(operation, symbolize_names: true)

      payload = Base64.urlsafe_decode64(@jws[:payload])
      header = Base64.urlsafe_decode64(@jws[:protected])

      op = JSON.parse(payload, symbolize_names: true)
      hdr = JSON.parse(header, symbolize_names: true)
      
      @sequence = op[:sequence]
      @previous = op[:previous]
      @timestamp = op[:timestamp]
      @version = op[:version]
      @actions = op[:actions]
      @signing_key = hdr[:kid]

      validate
    end

    def validate
      raise StandardError "unknown operation version" unless @version == "1.0.0"
      raise StandardError "invalid operation sequence" if @sequence < 0
      raise StandardError "operation does not specify a previous signature" if @previous.nil?
      raise StandardError "invalid operation timestamp" if @timestamp < 1
      raise StandardError "operation does not specify any actions" if @actions.nil?
      raise StandardError "operation does not specify any actions" if @actions.length < 1
      raise StandardError "operation does not specify an identifier for the signing key" if @kid.nil?
    end

    def revokes(kid)
      @actions.each do |action|
        return true if action[:kid] == kid && action[:action] = "key.revoke"
      end
      return false
    end
  end

  class Key

    attr_reader :kid, :did, :type, :created, :revoked, :public_key, :raw_public_key, :inbound, :outbound

    def initialize(action)
      @kid = action[:kid]
      @did = action[:did]
      @type = action[:type]
      @created = action[:from]
      @revoked = 0

      @raw_public_key = Base64.urlsafe_decode64(action[:key])
      @public_key = Ed25519::VerifyKey.new(@raw_public_key)

      @inbound = Array.new
      @outbound = Array.new
    end

    def valid_at(at)
      created <= at && revoked == 0 || created <= at && revoked > at
    end

    def revoke(at)
      @revoked = at
    end

    def revoked?
      @revoked > 0
    end

    def child_keys
      keys = @outbound.dup

      @outbound.each do |k|
        keys + k.child_keys
      end

      keys
    end
  end

  class SignatureGraph
    def initialize(history)
      @root = nil
      @keys = Hash.new
      @devices = Hash.new
      @signatures = Hash.new
      @operations = Array.new
      @recovery_key = nil

      history.each do |operation|
        execute(operation)        
      end
    end

    def key_by_id(kid)
      k = @keys[kid]
      raise StandardError "key not found" if k.nil?
      k
    end

    def key_by_device(did)
      k = @devices[did]
      raise StandardError "key not found" if k.nil?
      k
    end

    def execute(operation)
        op = Operation.new(operation)

        raise StandardError "operation sequence is out of order" if op.sequence != @operations.length
        
        if operation.sequence > 0 
          if @signatures[op.previous] != op.sequence - 1
            raise StandardError "operation previous signature does not match" 
          end

          if @operations[operation.sequence - 1].timestamp >= op.timestamp
            raise StandardError "operation timestamp occurs before previous operation"
          end

          sk = @keys[operation.siging_key]

          if sk.nil?
            raise StandardError "operation specifies a signing key that does not exist" 
          end

          if sk.revoked? && op.timestamp > sk.revoked_at
            raise StandardError "operation was signed by a key that was revoked at the time of signing"
          end

          if sk.type == "recovery.key" && op.revokes(operation.kid) != true
            raise StandardError "account recovery operation does not revoke the current active recovery key"
          end

          op.actions.each do |action|
            raise StandardError "operation action does not provide a key identifier" if action[:kid].nil?

            if action[:type] != "device.key" && action[:type] != "recovery.key"
              raise StandardError "operation action does not provide a valid type"
            end

            if action[:action] != "key.add" && action[:action] != "key.revoke"
              raise StandardError "operation action does not provide a valid action"
            end

            if action[:action] == "key.add" && action[:key].nil?
              raise StandardError "operation action does not provide a valid public key"
            end

            if action[:action] == "key.add" && action[:type] == "device.key" && action[:did].nil?
              raise StandardError "operation action does not provide a valid device id"
            end

            raise StandardError "operation action does not provide a valid timestamp for the action to take effect from" raise if action[:from] < 0

            case action[:type]
            when "key.add"
              action[:from] = op.timestamp
              add(op, action)
            when "key.revoke"
              revoke(op, action)
            end
          end
        end

        sk = @keys[op.signing_key]

        if op.timestamp < sk.created || sk.revoked > 0 && op.revoked
          raise StandardError "operation was signed with a key that was revoked"  
        end

        sig = Base64.urlsafe_decode64(op.jws[:signature])

        sk.public_key.verify(sig, "#{op.jws[:protected]}.#{op.jws[:payload]}")

        has_valid_key = false

        @keys.each |kid, k|
          has_valid_key = true unless k.revoked?
        end

        raise StandardError "signature graph does not contain any active or valid keys" unless has_valid_key
        raise StandardError "signature graph does not contain a valid recovery key" if @recovery_key.nil?
        raise StandardError "signature graph does not contain a valid recovery key" if @recovery_key.revoked?

        @operations.push(op)
        @signatures[op.jws[:signature]] = op.sequence
    end

    private

    def add(operation, action)
      if @keys[action[:kid]].nil? != true
        raise StandardError "operation contains a key with a duplicate identifier" 
      end

      k = Key.new(action)

      case a.type
      when "device.key"
        dk = @devices[action[:did]]
        if dk.nil? != true
          raise StandardError "operation contains more than one active key for a device" unless dk.revoked?
        end
      when "recovery.key"
        if @recovery_key.nil? != true
          raise StandardError "operation contains more than one active key for recovery" unless @recovery_key.revoked? 
        end

        @recovery_key = k
      end

      @keys[k.kid] = k
      @devices[k.did] = k

      if operation.sequence == 0 && op.signing_key == action.kid
        @root = k
        return
      end
      
      parent = @keys[operation.kid]

      raise StandardError "operation specifies a signing key that does not exist" if parent.nil?

      k.incoming.push(parent)
      parent.outgoing.push(k)
    end

    def revoke(operation, action)
      k = @keys[action[:kid]]

      raise StandardError "operation tries to revoke a key that does not exist" if k.nil?
      raise StandardError "root operation cannot revoke keys" if operation.sequence < 1
      raise StandardError "operation tries to revoke a key that has already been revoked" if k.revoked?

      k.revoke(action[:from])

      sk = @keys[operation.signing_key]

      raise StandardError "operation specifies a signing key that does not exist" if k.nil?

      # if this is an account recovery, nuke all existing keys
      if sk.type == "recovery.key"
        @root.revoke(action[:from])

        @root.child_keys.each do |ck|
          ck.revoke(action[:from]) unless ck.revoked?
        end
      else
        k.child_keys.each do |ck|
          ck.revoke(action[:from]) unless ck.created < action[:from]
        end
      end
    end
  end
end