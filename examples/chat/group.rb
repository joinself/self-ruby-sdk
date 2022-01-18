# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative '../../lib/selfsdk'
require_relative '../utilities/setup.rb'
require_relative '../utilities/colorize.rb'

@app = setup_sdk

@groups = {}

@app.chat.on_invite do |group|
  @groups[group.gid] = group
  group.join
  group.message("hi")
end

@app.chat.on_join do |msg|
  @groups[msg[:gid]].members << msg[:iss]
end

@app.chat.on_leave do |msg|
  @groups[msg[:gid]].members.delete(msg[:iss])
end

@app.chat.on_message do |msg|
  if msg.gid.nil?
    puts "#{msg.from}: #{msg.body}"
  else
    puts "[#{@groups[msg.gid].name}] #{msg.from}: #{msg.body}"
  end
end

sleep 100_000
