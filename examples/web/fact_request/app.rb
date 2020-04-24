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
    <!-- Login Form -->
    <form action="/facts" method="POST">
      <input type="text" id="login" name="selfid" class="fadeIn first" placeholder="SelfID" />
      <input type="submit" class="fadeIn second" value="Request facts" />
    </form>

@@ home
    <div class="fadeIn first row">
      <div class="col-md-1"></div>
      <div class="col-md-3 text-left">SelfID</div>
      <div class="col-md-7 form-control text-left"><%= @profile.selfid %></div>
      <div class="col-md-1"></div>
    </div>
    <div class="fadeIn second row">
      <div class="col-md-1"></div>
      <div class="col-md-3 text-left">Name</div>
      <div class="col-md-7 form-control text-left"><%= @profile.name %></div>
      <div class="col-md-1"></div>
    </div>
    <div class="fadeIn third row">
      <div class="col-md-1"></div>
      <div class="col-md-3 text-left">Email</div>
      <div class="col-md-7 form-control text-left"><%= @profile.email %></div>
      <div class="col-md-1"></div>
    </div>
    <a class="btn fadeIn fourth" href="/" >Try again</a>

@@ layout
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset="utf-8" />
      <title>Simple Fact Request Example</title>
      <link href="//maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" rel="stylesheet" id="bootstrap-css">
      <script src="//maxcdn.bootstrapcdn.com/bootstrap/4.0.0/js/bootstrap.min.js"></script>
      <script src="//cdnjs.cloudflare.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
      <style>
        html,body{height:100%;background-color:#0e1c42}.container{height:100%;display:flex;justify-content:center;align-items:center}input{display:block}.error{color:red}html{background-color:#0e1c42}body{font-family:"Poppins",sans-serif;height:100vh}a{color:#92badd;display:inline-block;text-decoration:none;font-weight:400}h2{text-align:center;font-size:16px;font-weight:600;text-transform:uppercase;display:inline-block;margin:40px 8px 10px;color:#ccc}.wrapper{display:flex;align-items:center;flex-direction:column;justify-content:center;width:100%;min-height:100%;padding:20px;background-color:#0e1c42}#formContent{-webkit-border-radius:10px 10px 10px 10px;border-radius:10px 10px 10px 10px;background:#fff;padding:30px;width:90%;max-width:450px;position:relative;padding:0;-webkit-box-shadow:0 30px 60px 0 rgba(0,0,0,0.3);box-shadow:0 30px 60px 0 rgba(0,0,0,0.3);text-align:center}#formFooter{color:#fff;background-color:#394263;border-top:1px solid #dce8f1;padding:25px;text-align:center;-webkit-border-radius:0 0 10px 10px;border-radius:0 0 10px 10px}h2.inactive{color:#ccc}h2.active{color:#0d0d0d;border-bottom:2px solid #5fbae9}input[type=button],input[type=submit],input[type=reset]{background-color:#56baed;border:none;color:#fff;padding:15px 80px;text-align:center;text-decoration:none;display:inline-block;text-transform:uppercase;font-size:13px;-webkit-box-shadow:0 10px 30px 0 rgba(95,186,233,0.4);box-shadow:0 10px 30px 0 rgba(95,186,233,0.4);-webkit-border-radius:5px 5px 5px 5px;border-radius:5px 5px 5px 5px;margin:5px 20px 40px;-webkit-transition:all .3s ease-in-out;-moz-transition:all .3s ease-in-out;-ms-transition:all .3s ease-in-out;-o-transition:all .3s ease-in-out;transition:all .3s ease-in-out}input[type=button]:hover,input[type=submit]:hover,input[type=reset]:hover{background-color:#39ace7}input[type=button]:active,input[type=submit]:active,input[type=reset]:active{-moz-transform:scale(0.95);-webkit-transform:scale(0.95);-o-transform:scale(0.95);-ms-transform:scale(0.95);transform:scale(0.95)}input[type=text]{background-color:#f6f6f6;border:none;color:#0d0d0d;padding:15px 32px;text-align:center;text-decoration:none;display:inline-block;font-size:16px;margin:5px;width:85%;border:2px solid #f6f6f6;-webkit-transition:all .5s ease-in-out;-moz-transition:all .5s ease-in-out;-ms-transition:all .5s ease-in-out;-o-transition:all .5s ease-in-out;transition:all .5s ease-in-out;-webkit-border-radius:5px 5px 5px 5px;border-radius:5px 5px 5px 5px}input[type=text]:focus{background-color:#fff;border-bottom:2px solid #5fbae9}input[type=text]:placeholder{color:#ccc}.fadeInDown{-webkit-animation-name:fadeInDown;animation-name:fadeInDown;-webkit-animation-duration:1s;animation-duration:1s;-webkit-animation-fill-mode:both;animation-fill-mode:both}@-webkit-keyframes fadeInDown{0%{opacity:0;-webkit-transform:translate3d(0,-100%,0);transform:translate3d(0,-100%,0)}100%{opacity:1;-webkit-transform:none;transform:none}}@keyframes fadeInDown{0%{opacity:0;-webkit-transform:translate3d(0,-100%,0);transform:translate3d(0,-100%,0)}100%{opacity:1;-webkit-transform:none;transform:none}}@-webkit-keyframes fadeIn{from{opacity:0}to{opacity:1}}@-moz-keyframes fadeIn{from{opacity:0}to{opacity:1}}@keyframes fadeIn{from{opacity:0}to{opacity:1}}.fadeIn{opacity:0;-webkit-animation:fadeIn ease-in 1;-moz-animation:fadeIn ease-in 1;animation:fadeIn ease-in 1;-webkit-animation-fill-mode:forwards;-moz-animation-fill-mode:forwards;animation-fill-mode:forwards;-webkit-animation-duration:1s;-moz-animation-duration:1s;animation-duration:1s}.fadeIn.first{-webkit-animation-delay:.4s;-moz-animation-delay:.4s;animation-delay:.4s}.fadeIn.second{-webkit-animation-delay:.6s;-moz-animation-delay:.6s;animation-delay:.6s}.fadeIn.third{-webkit-animation-delay:.8s;-moz-animation-delay:.8s;animation-delay:.8s}.fadeIn.fourth{-webkit-animation-delay:1s;-moz-animation-delay:1s;animation-delay:1s}.underlineHover:after{display:block;left:0;bottom:-10px;width:0;height:2px;background-color:#56baed;content:"";transition:width .2s}.underlineHover:hover{color:#0d0d0d}.underlineHover:hover:after{width:100%}:focus{outline:none}#icon{width:60%}
      </style>
    </head>
    <body>
      <div class="wrapper fadeInDown">
        <div id="formContent">
          <!-- Icon -->
          <div class="fadeIn first">
            <img src="https://storage.googleapis.com/self-public/images/logo.jpg" id="icon" alt="User Icon" style="width:120px" />
          </div>
          <% if @error %>
            <p class="error"><%= @error %></p>
          <% end %>

          <%= yield %>

        <!-- Remind Passowrd -->
        <div id="formFooter">
          <h4>Self fact request demonstration</h4>
          <p>Request user's name and email by introducing its SelfID</p>
        </div>
        </div>
      </div>
    </body>
  </html>