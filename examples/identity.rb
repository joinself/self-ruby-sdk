# frozen_string_literal: true

require_relative '../lib/selfid.rb'

@app = Selfid::App.new("2a9d2f7595b9c959ec212966dcb75efb", "4XraPyq9f38YT8lA+ZzspBXSgg6NtEwkiQD0qeLiOnE", self_url: "https://api.review.selfid.net")
identity = @app.identity("72921676292")
p identity
