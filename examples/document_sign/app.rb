# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true

require_relative '../../lib/selfsdk'
require_relative '../utilities/colorize.rb'
require_relative '../utilities/setup.rb'

@app = setup_sdk

terms = "Please, read and accept terms and conditions"

objects = []
File.open('./sample.pdf') do |f|
  objects << {
    name: "Terms and conditions",
    data: f.read,
    mime: 'application/pdf'
  }
end

@app.docs.request_signature ARGV[0], terms, objects do |resp|
  if resp.status == 'accepted'
    puts "Document signed!".green
    puts ''
    puts 'signed documents: '

    resp.signed_objects.each do |so|
      puts "- Name:  #{so[:name]}"
      puts "  Link:  #{so[:link]}"
      puts "  Hash:  #{so[:hash]}"
    end
    puts ''
    puts "full signature:"
    puts resp.input
  else
    puts "Document signature #{'rejected'.red}"
  end
  exit
end

sleep 100000