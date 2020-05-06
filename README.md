![SelfID logo](https://media-exp1.licdn.com/dms/image/C4E0BAQHiKfIfzq6P0w/company-logo_200_200/0?e=2159024400&v=beta&t=JDd8UXJlMG7AKpLNAP5nDYd75gQZT8E8s98xSc0jRO0)

By [Self ID](https://www.selfid.net/).

[![Build Status](https://api.travis-ci.org/selfid-net/selfid-gem.svg?branch=master)](http://travis-ci.org/selfid-net/selfid-gem)
[![Gem Version](https://badge.fury.io/rb/selfid.svg)](https://badge.fury.io/rb/selfid)

This gem provides a toolset to interact with self network from your ruby code.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'selfid'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install selfid

## Requirements

In order to use this gem you'll need to get your `app_id` and `app_api_key` from [self developer portal](https://developer.self.net).

## Usage

You can instantiate an app with the command above.
```ruby
# Require SelfID gem
require 'selfid'
# setup client connection
@client = Selfid::App.new(ENV['SELF_APP_ID'], ENV['SELF_APP_SECRET'], ENV['STORAGE_KEY'])
```

At this point your app will be able to interact with self network, find below some useful features.

### Authenticate

Authenticate allows your users to authenticate or register on your app. You can use a blocking, and a non-blocking approach:

```ruby
# This is a blocking approach to self authentication.
# send an authentication request
auth = @client.authentication.request("1112223334")
# check if the auth response is accepted
puts "You are now authenticated 🤘" if auth.accepted?
end
```
```ruby
# This is a non-blocking approach to self authentication.
# send an authentication request
@client.authentication.request "1112223334" do |auth|
  puts "You are now authenticated 🤘" if auth.accepted?
end
```

### Process incoming messages

Other peers on self network can send you messages, this client offers you a subscription model to process them by type.
```ruby
@client.authentication.subscribe do |auth|
  if auth.accepted?
    puts "#{auth.id} has accepted your auth request"
  else
  puts "#{auth.id} has rejected your auth request"
end
```

### Information or fact requests

You can request some information to other peers on the network. Same as with authentication you can do this using blocking and non-blocking approaches.
```ruby
# Blocking approach to fact request.
# request name and email values to 1112223334
res = @client.fact.request("1112223334", [:display_name, :email_address])
# print the returned values
puts "Hello #{res.attestation_values_for(:display_name).first}"
```
```ruby
# Non-blocking approach to fact request.
# request name and email values to 1112223334
@client.fact.request("1112223334", [:display_name, :email_address]) do |res|
  # print the returned values
  puts "Hello #{res.attestation_values_for(:display_name).first}"
end
```

### ACL management

Even when your app is created you set its default permissions so `Everyone` or `Just you` can interact with the app, this client offers some methods to manage this permissions, and in fact, who can interact with your app.

#### List ACL
```ruby
@app.messaging.allowed_connections
```
#### Allow new connections
```ruby
@app.messaging.permit_connection "1112223334"
```
#### Block incoming connections from the specified identity
```ruby
@app.messaging.revoke_connection "1112223334"
```

## Documentation

You can find general documentation for Self on [self docs site](https://docs.selfid.net/) and specifically for this library on [rubydoc](https://www.rubydoc.info/gems/selfid/).

## Examples

This gem comes with some examples built to help you have an idea of how or what to build on top of this library.
- [ACL management](examples/acl.rb)
- [Async registration](examples/async_registration.rb)
- [Sync registration](examples/sync_registration.rb)
- [Identity](examples/identity.rb)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/selfid-net/selfid-gem.


## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
