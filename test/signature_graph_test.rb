# frozen_string_literal: true

require_relative 'test_helper'
require 'selfsdk'
require "ed25519"

require 'webmock/minitest'
require 'timecop'

class SelfSDKTest < Minitest::Test
  describe "signature graph" do
    def test_valid_single_entry
      history = history_fixture('valid_single_entry')
      sg = SelfSDK::SignatureGraph.new(history)

      k = sg.key_by_id('0')
      assert_equal('0', k.kid)
      assert_equal('device-1', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356708, k.created)
      assert_equal(0, k.revoked)
      assert_equal(false, k.revoked?)
      assert_equal(true, k.valid_at(1598356709))
      assert_equal(true, k.valid_at(1598356708))
      assert_equal(false, k.valid_at(1598356707))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('1')
      assert_equal('1', k.kid)
      assert_nil(k.did)
      assert_equal('recovery.key', k.type)
      assert_equal(1598356708, k.created)
      assert_equal(0, k.revoked)
      assert_equal(false, k.revoked?)
      assert_equal(true, k.valid_at(1598356709))
      assert_equal(true, k.valid_at(1598356708))
      assert_equal(false, k.valid_at(1598356707))
      assert_equal(false, k.public_key.nil?)
    end

    def test_valid_multi_entry
      history = history_fixture('valid_multi_entry')
      sg = SelfSDK::SignatureGraph.new(history)

      k = sg.key_by_id('0')
      assert_equal('0', k.kid)
      assert_equal('device-1', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356708, k.created)
      assert_equal(0, k.revoked)
      assert_equal(false, k.revoked?)
      assert_equal(true, k.valid_at(1598356709))
      assert_equal(true, k.valid_at(1598356708))
      assert_equal(false, k.valid_at(1598356707))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('1')
      assert_equal('1', k.kid)
      assert_nil(k.did)
      assert_equal('recovery.key', k.type)
      assert_equal(1598356708, k.created)
      assert_equal(0, k.revoked)
      assert_equal(false, k.revoked?)
      assert_equal(true, k.valid_at(1598356709))
      assert_equal(true, k.valid_at(1598356708))
      assert_equal(false, k.valid_at(1598356707))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('2')
      assert_equal('2', k.kid)
      assert_equal('device-2', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356709, k.created)
      assert_equal(1598356712, k.revoked)
      assert_equal(true, k.revoked?)
      assert_equal(true, k.valid_at(1598356710))
      assert_equal(true, k.valid_at(1598356709))
      assert_equal(false, k.valid_at(1598356708))
      assert_equal(false, k.valid_at(1598356712))
      assert_equal(false, k.valid_at(1598356713))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('3')
      assert_equal('3', k.kid)
      assert_equal('device-3', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356710, k.created)
      assert_equal(0, k.revoked)
      assert_equal(false, k.revoked?)
      assert_equal(true, k.valid_at(1598356711))
      assert_equal(true, k.valid_at(1598356710))
      assert_equal(false, k.valid_at(1598356709))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('4')
      assert_equal('4', k.kid)
      assert_equal('device-4', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356711, k.created)
      assert_equal(0, k.revoked)
      assert_equal(false, k.revoked?)
      assert_equal(true, k.valid_at(1598356712))
      assert_equal(true, k.valid_at(1598356711))
      assert_equal(false, k.valid_at(1598356710))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('5')
      assert_equal('5', k.kid)
      assert_equal('device-2', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356712, k.created)
      assert_equal(0, k.revoked)
      assert_equal(false, k.revoked?)
      assert_equal(true, k.valid_at(1598356713))
      assert_equal(true, k.valid_at(1598356712))
      assert_equal(false, k.valid_at(1598356711))
      assert_equal(false, k.public_key.nil?)
    end

    def test_valid_multi_entry_with_recovery
      history = history_fixture('valid_multi_entry_with_recovery')
      sg = SelfSDK::SignatureGraph.new(history)

      k = sg.key_by_id('0')
      assert_equal('0', k.kid)
      assert_equal('device-1', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356708, k.created)
      assert_equal(1598356713, k.revoked)
      assert_equal(true, k.revoked?)
      assert_equal(true, k.valid_at(1598356709))
      assert_equal(true, k.valid_at(1598356708))
      assert_equal(false, k.valid_at(1598356707))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('1')
      assert_equal('1', k.kid)
      assert_nil(k.did)
      assert_equal('recovery.key', k.type)
      assert_equal(1598356708, k.created)
      assert_equal(1598356713, k.revoked)
      assert_equal(true, k.revoked?)
      assert_equal(true, k.valid_at(1598356709))
      assert_equal(true, k.valid_at(1598356708))
      assert_equal(false, k.valid_at(1598356707))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('2')
      assert_equal('2', k.kid)
      assert_equal('device-2', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356709, k.created)
      assert_equal(1598356712, k.revoked)
      assert_equal(true, k.revoked?)
      assert_equal(true, k.valid_at(1598356710))
      assert_equal(true, k.valid_at(1598356709))
      assert_equal(false, k.valid_at(1598356708))
      assert_equal(false, k.valid_at(1598356712))
      assert_equal(false, k.valid_at(1598356713))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('3')
      assert_equal('3', k.kid)
      assert_equal('device-3', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356710, k.created)
      assert_equal(1598356713, k.revoked)
      assert_equal(true, k.revoked?)
      assert_equal(true, k.valid_at(1598356711))
      assert_equal(true, k.valid_at(1598356710))
      assert_equal(false, k.valid_at(1598356709))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('4')
      assert_equal('4', k.kid)
      assert_equal('device-4', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356711, k.created)
      assert_equal(1598356713, k.revoked)
      assert_equal(true, k.revoked?)
      assert_equal(true, k.valid_at(1598356712))
      assert_equal(true, k.valid_at(1598356711))
      assert_equal(false, k.valid_at(1598356710))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('5')
      assert_equal('5', k.kid)
      assert_equal('device-2', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356712, k.created)
      assert_equal(1598356713, k.revoked)
      assert_equal(true, k.revoked?)
      assert_equal(true, k.valid_at(1598356712))
      assert_equal(false, k.valid_at(1598356711))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('6')
      assert_equal('6', k.kid)
      assert_equal('device-1', k.did)
      assert_equal('device.key', k.type)
      assert_equal(1598356713, k.created)
      assert_equal(0, k.revoked)
      assert_equal(false, k.revoked?)
      assert_equal(true, k.valid_at(1598356714))
      assert_equal(true, k.valid_at(1598356713))
      assert_equal(false, k.valid_at(1598356712))
      assert_equal(false, k.public_key.nil?)

      k = sg.key_by_id('7')
      assert_equal('7', k.kid)
      assert_nil(k.did)
      assert_equal('recovery.key', k.type)
      assert_equal(1598356713, k.created)
      assert_equal(0, k.revoked)
      assert_equal(false, k.revoked?)
      assert_equal(true, k.valid_at(1598356714))
      assert_equal(true, k.valid_at(1598356713))
      assert_equal(false, k.valid_at(1598356712))
      assert_equal(false, k.public_key.nil?)
    end

    def test_invalid_sequence_ordering
      history = history_fixture('invalid_sequence_ordering')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end

      assert_equal('operation sequence is out of order', exception.message)
    end

    def test_invalid_timestamp
      history = history_fixture('invalid_timestamp')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end

      assert_equal('operation timestamp occurs before previous operation', exception.message)
    end

    def test_invalid_previous_signature
      history = history_fixture('invalid_previous_signature')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
      
      assert_equal('operation previous signature does not match', exception.message)
    end

    def test_invalid_duplicate_key_identifier
      history = history_fixture('invalid_duplicate_key_identifier')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
        
      assert_equal('operation contains a key with a duplicate identifier', exception.message)
    end
    
    def test_invalid_no_active_keys
      history = history_fixture('invalid_no_active_keys')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
          
      assert_equal('signature graph does not contain any active or valid keys', exception.message)
    end

    def test_invalid_no_active_recovery_keys
      history = history_fixture('invalid_no_active_recovery_keys')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
            
      assert_equal('signature graph does not contain a valid recovery key', exception.message)
    end

    def test_invalid_multiple_recovery_keys
      history = history_fixture('invalid_multiple_recovery_keys')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
              
      assert_equal('operation contains more than one active recovery key', exception.message)
    end

    def test_invalid_multiple_device_keys
      history = history_fixture('invalid_multiple_device_keys')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                
      assert_equal('operation contains more than one active key for a device', exception.message)
    end

    def test_invalid_revoked_key_creation
      history = history_fixture('invalid_revoked_key_creation')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                  
      assert_equal('operation was signed by a key that was revoked at the time of signing', exception.message)
    end

    def test_invalid_signing_key
      history = history_fixture('invalid_signing_key')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                    
      assert_equal('operation specifies a signing key that does not exist', exception.message)
    end

    def test_invalid_recovery_no_revoke
      history = history_fixture('invalid_recovery_no_revoke')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                      
      assert_equal('account recovery operation does not revoke the current active recovery key', exception.message)
    end
    
    def test_invalid_empty_actions
      history = history_fixture('invalid_empty_actions')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                        
      assert_equal('operation does not specify any actions', exception.message)
    end
    
    def test_invalid_already_revoked_key
      history = history_fixture('invalid_already_revoked_key')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                          
      assert_equal('operation tries to revoke a key that has already been revoked', exception.message)
    end

    def test_invalid_key_reference
      history = history_fixture('invalid_key_reference')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                            
      assert_equal('operation tries to revoke a key that does not exist', exception.message)
    end
    
    def test_invalid_root_operation_key_revocation
      history = history_fixture('invalid_root_operation_key_revocation')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                              
      assert_equal('root operation cannot revoke keys', exception.message)
    end

    def test_invalid_operation_signature
      history = history_fixture('invalid_operation_signature')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                                
      assert_equal('signature verification failed!', exception.message)
    end
    
    def test_invalid_operation_signature_root
      history = history_fixture('invalid_operation_signature_root')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                                  
      assert_equal('signature verification failed!', exception.message)
    end

    def test_invalid_revocation_before_root_operation_timestamp
      history = history_fixture('invalid_revocation_before_root_operation_timestamp')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                                  
      assert_equal('operation was signed with a key that was revoked', exception.message)
    end
    
    def test_invalid_operation_version
      history = history_fixture('invalid_revocation_before_root_operation_timestamp')
      exception = assert_raises StandardError do
        sg = SelfSDK::SignatureGraph.new(history)
      end
                                    
      assert_equal('operation was signed with a key that was revoked', exception.message)
    end

    def history_fixture(name)
      f = File.read("./test/fixtures/#{name}.json")
      JSON.parse(f, symbolize_names: true)
    end
  end
end