# frozen_string_literal: true

require_relative '../lib/selfid.rb'

# invalid input
john_id = "a34c5303aae00bcec156c3ecb1665d7e"
john_seed = "NLslMyWKNlRZbBmRlyztXDxqyEki37yfzj3O13acDtY"
sarah_id = "b059c086d39bdfe0f7b8ea354eb69185"
sarah_seed = "MDZtX4lXoaWSj/WivKAn4mD1I1xcDgq4nJeA/dPwKXw"
adria_id = "32287532230"

@sarah = Selfid::App.new(sarah_id, sarah_seed, self_url: "http://localhost:8080", messaging_url: "ws://localhost:8086/v1/messaging")
@john = Selfid::App.new(john_id, john_seed, self_url: "http://localhost:8080", messaging_url: "ws://localhost:8086/v1/messaging")

@sarah.connect(john_id)
@john.connect(sarah_id)
@john.connect(adria_id)

# @john.request_information(adria_id, ["passport_last_name"], type: :async)
# return
p "john is requesting information"

sleep 1
p "Sarah getting unread messages"
Thread.new do
  loop do
    @sarah.inbox.each do |m|
      p "Sarah sharing information with John"
      m.share_facts(
        "passport_first_name": @john.jwt.prepare_encoded(
          cid: SecureRandom.uuid,
          jti: SecureRandom.uuid,
          iss: john_id,
          sub: sarah_id,
          iat: Time.now.utc.strftime('%FT%TZ'),
          source: "user-specified",
          passport_first_name: "Sarah"
        ),
      )
    end
    @sarah.clear_inbox
  end
end

sleep 3
@john.request_information(sarah_id, ["passport_last_name"])

p "================"
p "John received Sarah's fields"
p @john.inbox.first.facts[:passport_first_name].value
if @john.inbox.first.facts[:passport_first_name].verified
  p "Verified"
else
  p "Not verified"
end
p "================"
