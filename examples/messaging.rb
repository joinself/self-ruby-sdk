require_relative '../lib/selfid.rb'

# invalid input
john_id = "550212347ac0b77d9def3ec75e56fe5b"
john_seed = "skKvOv7UBGYyoaAlYQ5N0QZE5Llm+7lsfGSmy2Hy2CU"
steff_id = "aff02d5b5faaf1c74bc626c6036ac776"
steff_seed = "tRtWcwlZNqo2L3vXpjhE3WMFdjBXyzetGGgGU97ALBs"
andrew_id = "b3605daf40b137f78a4a3959b58a8a37"
andrew_seed = "HWdVH91U9yGg47gigEiqe9rnSVA7M/2TNbffMGP0rCg"

@steff = Selfid::App.new(steff_id, steff_seed, self_url: "http://localhost:8080", messaging_url: "ws://localhost:8086/v1/messaging")
@john = Selfid::App.new(john_id, john_seed, self_url: "http://localhost:8080", messaging_url: "ws://localhost:8086/v1/messaging")

@steff.connect(john_id)
@john.connect(steff_id)

"john is requesting information"
@john.request_information(steff_id, ["a","b","c"], type: :async)

require 'pry'; binding.pry
p "stef getting unread messages"
@steff.inbox.each do |m|
  p m
end
