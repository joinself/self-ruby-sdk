# frozen_string_literal: true

require 'date'

# Namespace for classes and modules that handle Self interactions.
module SelfSDK
  # Access control list
  class ACL
    def initialize(messaging)
      @messaging = messaging
      @jwt = @messaging.jwt
    end

    # Lists allowed connections.
    def list
      SelfSDK.logger.info "Listing allowed connections"
      rules = {}
      @messaging.list_acl_rules.each do |c|
        rules[c['acl_source']] = DateTime.parse(c['acl_exp'])
      end
      rules
    end

    # Allows incomming messages from the given identity.
    def allow(id)
      SelfSDK.logger.info "Allowing connections from #{id}"
      @messaging.add_acl_rule(@jwt.prepare(jti: SecureRandom.uuid,
                                           cid: SecureRandom.uuid,
                                           typ: 'acl.permit',
                                           iss: @jwt.id,
                                           sub: @jwt.id,
                                           iat: (SelfSDK::Time.now - 5).strftime('%FT%TZ'),
                                           exp: (SelfSDK::Time.now + 60).strftime('%FT%TZ'),
                                           acl_source: id,
                                           acl_exp: (SelfSDK::Time.now + 360_000).to_datetime.rfc3339))
    end

    # Deny incomming messages from the given identity.
    def deny(id)
      SelfSDK.logger.info "Denying connections from #{id}"
      @messaging.remove_acl_rule(@jwt.prepare(jti: SecureRandom.uuid,
                                               cid: SecureRandom.uuid,
                                               typ: 'acl.revoke',
                                               iss: @jwt.id,
                                               sub: @jwt.id,
                                               iat: (SelfSDK::Time.now - 5).strftime('%FT%TZ'),
                                               exp: (SelfSDK::Time.now + 60).strftime('%FT%TZ'),
                                               acl_source: id,
                                               acl_exp: (SelfSDK::Time.now + 360_000).to_datetime.rfc3339))
    end
  end
end
