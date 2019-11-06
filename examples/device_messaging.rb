# frozen_string_literal: true

require_relative '../lib/selfid.rb'

john_id = "a307a26bf6866c0a644bcb29cae3ef0d"
john_seed = "fNYtO0LcH4YCaCipBPFtBVUP8e+0A8e2dleIJTpzHsg"
adria_id = "61940310173"

@john = Selfid::App.new(john_id, john_seed, self_url: "http://localhost:8080", messaging_url: "ws://localhost:8086/v1/messaging")

@john.connect(adria_id)

res = @john.request_information(adria_id, ["email", "passport_first_name", "passport_last_name"])

p "================"
p "Received facts"
p "#{res.facts[:email].name} : #{res.facts[:email].value} (#{res.facts[:email].verified})"
p "#{res.facts[:passport_first_name].name} : #{res.facts[:passport_first_name].value} (#{res.facts[:passport_first_name].verified})"
p "#{res.facts[:passport_last_name].name} : #{res.facts[:passport_last_name].value} (#{res.facts[:passport_last_name].verified})"
p "================"

return
