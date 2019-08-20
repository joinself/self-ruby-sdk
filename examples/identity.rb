# frozen_string_literal: true

require_relative "lib/selfid"

@app = Selfid::App.new("od4pepkd4jl", "uNX0avmVxLUD1BidV7tO4kyUc818WS65+pAcvGZb87o", self_url: "http://192.168.0.93:8080")
identity = @app.identity("62787614127")
p identity
