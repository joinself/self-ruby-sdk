# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative '../../lib/selfsdk'
require_relative '../utilities/colorize.rb'

@app = setup_sdk

@app.chat.subscribe_to_messages do |msg|
  msg.mark_as_delivered
  msg.mark_as_read
  msg.respond("hi!")

  resp = msg.message("howre you doin?")
  sleep 2
  resp.edit("how're you doing?")
  sleep 3
  resp.delete!
end

sleep 100000