#!/user/bin/env ruby

require 'bundler/inline'
gemfile(true) do
  source 'https://rubygems.org'
  gem 'sinatra', '~> 1.4'
  gem 'selfid'
end

require 'sinatra/base'
require 'selfid'

Profile = Struct.new(:selfid, :name, :email)
USER = nil

class AuthExample < Sinatra::Base
  enable :inline_templates
  enable :sessions
  set :bind, '0.0.0.0'

  # Initialize self sdk client on the initialization to avoid multiple instances to be ran together.
  configure do
    # You can point to a different environment by passing optional values to the initializer in
    # case you need to
    opts = ENV.has_key?('SELF_BASE_URL') ? { base_url: ENV["SELF_BASE_URL"], messaging_url: ENV["SELF_MESSAGING_URL"] } : {}

    # Connect your app to Self network, get your connection details creating a new
    # app on https://developer.selfid.net/
    set :client, Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], opts)
  end

  # This is the default app endpoint which will be redirecting non-logged in users to facts
  get '/' do
    erb :facts
  end

  #
  post '/facts' do
    res = settings.client.facts.request(params['selfid'], [Selfid::FACT_DISPLAY_NAME, Selfid::FACT_EMAIL])
    if res.status == "rejected" # The user has rejected your fact request
      @error = "Fact request has been rejected"
      erb :facts
    else # The user accepted your fact request
      @profile =  Profile.new(params['selfid'],
                              res.fact(Selfid::FACT_DISPLAY_NAME).attestations.first.value,
                              res.fact(Selfid::FACT_EMAIL).attestations.first.value)
      erb :home
    end
  rescue => e # There was an error when you tried to reach the user (timeout, lack of permissions...)
    @error = "Error: #{e.message}"
    erb :facts
  end

  helpers do
    # Returns the signed in user if any
    def current_user
      session[:self_id]
    end
  end

  run!
end

__END__

@@ facts
  <h1>Requesting facts</h1>
  <% if @error %>
    <p class="error"><%= @error %></p>
  <% end %>
  <form action="/facts" method="POST">
    <input name="selfid" placeholder="SelfID" />
    <input type="submit" value="Sign In" />
  </form>

@@ home
  <p>SelfID : <%= @profile.selfid %></p>
  <p>Name : <%= @profile.name %></p>
  <p>Email : <%= @profile.email %></p>
  <a href="/">Try again</a>

@@ layout
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset="utf-8" />
      <title>Simple Fact Request Example</title>
      <style>
        input { display: block; }
        .error { color: red; }
      </style>
    </head>
    <body><%= yield %></body>
  </html>