require_relative '../lib/selfid.rb'

# invalid input
john_id = "03c0e8d17652d52799997af354b7254f"
john_seed = "nnby5QIq2+xkKTrylwS1eOB06cT6qHhVdEsFSGGwMkw"
sarah_id = "b14309f6d73b24e9b172ad664f0fd8a9"
sarah_seed = "dGCJlGDgNzIlL0rzDaj/MOipLkZG1vqz9tG2LXJXpR0"
adria_id = "37453024743"

@sarah = Selfid::App.new(sarah_id, sarah_seed, self_url: "http://localhost:8080", messaging_url: "ws://localhost:8086/v1/messaging")
@john = Selfid::App.new(john_id, john_seed, self_url: "http://localhost:8080", messaging_url: "ws://localhost:8086/v1/messaging")

@sarah.connect(john_id)
@john.connect(sarah_id)
@john.connect(adria_id)

p "john is requesting information"
# TODO Duplicate this call as there is a bug on self-messaging
@john.request_information(sarah_id, ["passport_last_name"], type: :async)

sleep 1
p "Sarah getting unread messages"
@sarah.inbox.each do |k, m|
  p "Sarah sharing information with John"
  m.share_facts({
    "passport_first_name": "Sarah",
    "passport_last_name": "Connor",
  })
end

sleep 3
@john.inbox.each do |k, m|
  p "processing #{k}"
  p m.to_json
end
require 'pry'; binding.pry

sleep 1000000
