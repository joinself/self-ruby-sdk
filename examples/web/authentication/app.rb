#!/user/bin/env ruby

require 'bundler/inline'
gemfile(true) do
  source 'https://rubygems.org'
  gem 'sinatra', '~> 1.4'
  gem 'selfid'
end

require 'sinatra/base'
require 'selfid'

class AuthExample < Sinatra::Base
  enable :inline_templates
  enable :sessions

  # Initialize self sdk client on the initialization to avoid multiple instances to be ran together.
  configure do
    # You can point to a different environment by passing optional values to the initializer in
    # case you need to
    opts = ENV.has_key?('SELF_BASE_URL') ? { base_url: ENV["SELF_BASE_URL"], messaging_url: ENV["SELF_MESSAGING_URL"] } : {}

    # Connect your app to Self network, get your connection details creating a new
    # app on https://developer.selfid.net/
    set :client, Selfid::App.new(ENV["SELF_APP_ID"], ENV["SELF_APP_SECRET"], opts)
  end

  # This is the default app endpoint which will be redirecting non-logged in users to sign_in
  get '/' do
    if current_user
      erb :home
    else
      redirect '/sign_in'
    end
  end

  # Display the form so your users can introduce their selfid
  get '/sign_in' do
    erb :sign_in
  end

  # Authenticate the input user using selfid
  post '/sign_in' do
    auth = settings.client.authentication.request params[:selfid]
    if auth.accepted? # The user accepts your authentication request
      session.clear
      session[:user_id] = params[:selfid]
      redirect '/'
    else # The user rejected the authentication request
      @error = "Authentication request has been rejected"
      erb :sign_in
    end
  rescue => e # There was an error when you tried to reach the user (timeout, lack of permissions...)
    @error = "Error: #{e.message}"
    erb :sign_in
  end

  # Endpoint to log out
  post '/sign_out' do
    session.clear
    redirect '/sign_in'
  end

  helpers do
    # Returns the signed in user if any
    def current_user
      session[:user_id]
    end
  end

  run!
end

__END__

@@ sign_in
  <h1>Sign in</h1>
  <% if @error %>
    <p class="error"><%= @error %></p>
  <% end %>
  <form action="/sign_in" method="POST">
    <input name="selfid" placeholder="SelfID" />
    <input type="submit" value="Sign In" />
  </form>

@@ home
  <h1>Home</h1>
  <p>Hello, <%= current_user %>. you've been successfully logged in</p>
  <form action="/sign_out" method="POST">
    <input type="submit" value="Sign Out" />
  </form>

@@ layout
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset="utf-8" />
      <title>Simple Authentication Example</title>
      <style>
        input { display: block; }
        .error { color: red; }
      </style>
    </head>
    <body><%= yield %></body>
  </html>