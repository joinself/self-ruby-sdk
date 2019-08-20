# frozen_string_literal: true

require 'sinatra'
require 'selfid'

class WebApp < Sinatra::Base
  configure do
    set :self_id, "od4pepkd4jl"
    set :self_key, "uNX0avmVxLUD1BidV7tO4kyUc818WS65+pAcvGZb87o"
    set :app, Selfid::App.new(self_id, self_key)
  end

  post '/selfid/auth/' do
    puts "authentication requested"
    @app.authenticate(params[:selfid], "http://<my_ip>/selfid/callback")
  end

  post '/selfid/callback' do
    if @app.authenticated?(request.body.read.to_s)
      puts "authentication accepted"
    else
      puts "authentication denied"
    end
  end
end
