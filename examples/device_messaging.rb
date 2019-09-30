require_relative '../lib/selfid.rb'

john_id = "a34c5303aae00bcec156c3ecb1665d7e"
john_seed = "NLslMyWKNlRZbBmRlyztXDxqyEki37yfzj3O13acDtY"
adria_id = "32287532230"

@john = Selfid::App.new(john_id, john_seed, self_url: "http://localhost:8080", messaging_url: "ws://localhost:8086/v1/messaging")

@john.connect(adria_id)

@john.request_information(adria_id, ["passport_last_name"], type: :async)
return
