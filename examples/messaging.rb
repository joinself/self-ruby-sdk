require_relative '../lib/selfid.rb'

# invalid input
john_id = "bdafcceb06835e4b8e5720da1b704941"
john_seed = "N4Aw9E0BkEVssLMWufzKVtcuy91NKe6bLqKpO4Ltgos"
sarah_id = "514aa2e0555abb0327d9f4f13a749a31"
sarah_seed = "Yw+mCVhb4oYjjFvobNOQPh5KBDvTXOz4JtxynwEeRpU"
adria_id = "28770731872"

@sarah = Selfid::App.new(sarah_id, sarah_seed, self_url: "http://localhost:8080", messaging_url: "ws://localhost:8086/v1/messaging")
@john = Selfid::App.new(john_id, john_seed, self_url: "http://localhost:8080", messaging_url: "ws://localhost:8086/v1/messaging")

@sarah.connect(john_id)
@john.connect(sarah_id)
@john.connect(adria_id)

# =begin
@john.request_information(adria_id, ["passport_last_name"], type: :async)
return
# =end
p "john is requesting information"
# TODO Duplicate this call as there is a bug on self-messaging
@john.request_information(sarah_id, ["passport_last_name"], type: :async)

sleep 1
p "Sarah getting unread messages"
@sarah.inbox.each do |m|
  p "Sarah sharing information with John"
  m.share_facts({
    "passport_first_name": "Sarah",
    "passport_last_name": "Connor",
  })
end

sleep 3
p "================"
p "John received Sarah's fields"
p @john.inbox.first.fields
p "================"
