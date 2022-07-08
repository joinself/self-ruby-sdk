![Self logo](https://media-exp1.licdn.com/dms/image/C4E0BAQHiKfIfzq6P0w/company-logo_200_200/0?e=2159024400&v=beta&t=JDd8UXJlMG7AKpLNAP5nDYd75gQZT8E8s98xSc0jRO0)

By [Self ID](https://www.joinself.com/).

![Build Status](https://github.com/joinself/self-ruby-sdk/actions/workflows/ci.yml/badge.svg?branch=main)
[![Gem Version](https://badge.fury.io/rb/selfsdk.svg)](https://badge.fury.io/rb/selfsdk)

This gem provides a toolset to interact with self network from your ruby code.

## Installation

### Requirements

- [libself-olm](http://download.selfid.net/olm/libself-olm_0.1.17_amd64.deb)
- [libself-omemo](http://download.selfid.net/omemo/libself-omemo_0.1.2_amd64.deb)

#### Debian/Ubuntu
```sh
$ curl -O http://download.joinself.com/olm/libself-olm_0.1.17_amd64.deb
$ curl -O http://download.joinself.com/omemo/libself-omemo_0.1.2_amd64.deb
$ apt install libsodium-dev
$ apt install ./libself-olm_0.1.17_amd64.deb ./libself-omemo_0.1.2_amd64.deb
```

#### Redhat/Centos
```sh
$ rpm -Uvh http://download.joinself.com/olm/libself-olm-0.1.14-1.x86_64.rpm
$ rpm -Uvh http://download.joinself.com/omemo/libself-omemo-0.1.2-1.x86_64.rpm
```

#### Mac
```sh
$ brew tap joinself/crypto
$ brew install libself_olm libself_omemo
```

## Usage

Add this line to your application's Gemfile:

```ruby
gem 'selfsdk'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install selfsdk

## Requirements

In order to use this gem you'll need to get your `app_id` and `app_api_key` from [self developer portal](https://developer.self.net).

## Usage

You can instantiate an app with the command above.
```ruby
# Require selfsdk gem
require 'selfsdk'
# setup client connection
@client = SelfSDK::App.new(ENV['SELF_APP_ID'], ENV['SELF_APP_DEVICE_SECRET'], ENV['STORAGE_KEY'], ENV['STORAGE_DIR'])
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

You can find general documentation for Self on [self docs site](https://docs.joinself.com/) and specifically for this library on [rubydoc](https://www.rubydoc.info/gems/selfsdk/).

## Examples

This gem comes with some examples built to help you have an idea of how or what to build on top of this library.
- [ACL management](examples/acl.rb)
- [Async registration](examples/async_registration.rb)
- [Sync registration](examples/sync_registration.rb)
- [Identity](examples/identity.rb)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

This project uses semantic versioning https://semver.org/. To create a new version run `bundle exec rake bump:(major|minor|patch)` depending on the version number you wish to increment. This will update the applications version as well as rebuild the dependencies to include the new version. Upon changes being merged into mainstream a new gem will be built, tagged and published to RubyGems.

### Developer commands

#### rake sources:generate

Generates the valid sources based on a json file (config/sources.json) instead of have them hardcoded on the gem.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joinself/self-ruby-sdk.


## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
