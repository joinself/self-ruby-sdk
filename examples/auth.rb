# frozen_string_literal: true

require 'sinatra'
require_relative '../lib/selfid.rb'

class WebApp < Sinatra::Base
  configure do
    set :app, Selfid::App.new("ogpmgzngpfj", "7kVR5NBjri20l9aFESXLaXlHZ4WSx2y/gFN3Un97ipU", self_url: "http://192.168.0.93:8080")
  end

  post '/selfid/auth' do
    puts "authentication requested for #{params[:selfid]}"
    settings.app.authenticate(params[:selfid], "http://85df98e8.ngrok.io/selfid/callback")
  end

  post '/selfid/callback' do
    if settings.app.authenticated?(request.body.read.to_s)
      puts "authentication accepted"
    else
      puts "authentication denied"
    end
  end
end

WebApp.run!
