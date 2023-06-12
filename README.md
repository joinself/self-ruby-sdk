# Self Ruby SDK

[![CI](https://github.com/joinself/self-ruby-sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/joinself/self-ruby-sdk/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/selfsdk.svg)](https://badge.fury.io/rb/selfsdk)

The official Self SDK for Ruby.

This SDK provides a toolset to interact with Self network from your ruby code.

## Installation

### Dependencies

- [Ruby](https://www.ruby-lang.org/) 3.0 or later
- [Self OLM](https://github.com/joinself/self-olm)
- [Self OMEMO](https://github.com/joinself/self-omemo)
- [Flatbuffers](https://flatbuffers.dev/)

##### Debian/Ubuntu
```bash
apt install -y libsodium-dev
curl -O https://download.joinself.com/olm/libself-olm_0.1.39_amd64.deb
curl -O https://download.joinself.com/omemo/libself-omemo_0.1.23_amd64.deb
apt install -y ./libself-olm_0.1.39_amd64.deb ./libself-omemo_0.1.23_amd64.deb

apt install -y cmake g++
git clone https://github.com/google/flatbuffers.git
cd flatbuffers
git checkout v2.0.0
cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release
make install
```

##### CentOS/RedHat
```bash
yum install -y libsodium
rpm -Uvh https://download.joinself.com/olm/libself-olm-0.1.39-1.x86_64.rpm
rpm -Uvh https://download.joinself.com/omemo/libself-omemo-0.1.23-1.x86_64.rpm
```

##### Fedora
```bash
dnf install -y libsodium
dnf install -y https://download.joinself.com/olm/libself-olm-0.1.39-1.x86_64.rpm
dnf install -y https://download.joinself.com/omemo/libself-omemo-0.1.23-1.x86_64.rpm
```

##### MacOS - AMD64
```bash
brew tap joinself/crypto
brew install libself-olm libself-omemo
```

##### MacOS - ARM64
Brew on M1 macs currently lacks environment variables needed for the SDK to find the `olm` and `omemo` libraries, so you will need to add some additional configuration to your system:

In your `~/.zshrc`, add:
```bash
export C_INCLUDE_PATH=/opt/homebrew/include/
export LIBRARY_PATH=$LIBRARY_PATH:/opt/homebrew/lib
```

You should then be able to run:

```bash
source ~/.zshrc
brew tap joinself/crypto
brew install --build-from-source libself-olm libself-omemo
```

Note, you may also need to create `/usr/local/lib` if it does not exist:
```bash
sudo mkdir /usr/local/lib
```

### Install

```bash
gem install selfsdk
```

## Usage

### Register Application

Before the SDK can be used you must first register an application on the Self Developer Portal. Once registered, the portal will generate credentials for the application that the SDK will use to authenticate against the Self network.

Self provides two isolated networks:

[Developer Portal (production network)](https://developer.joinself.com) - Suitable for production services  
[Developer Portal (sandbox network)](https://developer.sandbox.joinself.com) - Suitable for testing and experimentation

Register your application using one of the links above ([further information](https://docs.joinself.com/quickstart/app-setup/)).

### Examples

#### Client Setup

```ruby
require 'selfsdk'

@client = SelfSDK::App.new("<application-id>", "<application-secret-key>", "random-secret-string", "/data")

@client.start
```

#### Authentication

Authentication allows your users to authenticate or register on your app.

Blocking:
```ruby
auth = @client.authentication.request("<self-id>")
puts "You are now authenticated 🤘" if auth.accepted?
```

Non-blocking:
```ruby
@client.authentication.request "<self-id>" do |auth|
  puts "You are now authenticated 🤘" if auth.accepted?
end
```

#### Process Incoming Messages

Other peers on self network can send you messages, this client offers you a subscription model to process them by type.

```ruby
@client.authentication.subscribe do |auth|
  if auth.accepted?
    puts "#{auth.id} has accepted your auth request"
  else
    puts "#{auth.id} has rejected your auth request"
  end
end
```

#### Information or Fact Requests

You can request some information to other peers on the network. Same as with authentication you can do this using blocking and non-blocking approaches.

Blocking:
```ruby
res = @client.fact.request("<self-id>", [:display_name, :email_address])
puts "Hello #{res.attestation_values_for(:display_name).first}"
```

Non-blocking:
```ruby
@client.fact.request("<self-id>", [:display_name, :email_address]) do |res|
  puts "Hello #{res.attestation_values_for(:display_name).first}"
end
```

#### ACL Management

ACL's control who can and can't interact with the application. When registering your application you can set a default ACL to allow `Everyone` or `Just you`.

List ACL's:
```ruby
@app.messaging.allowed_connections
```

Allow connection from a specific identity:
```ruby
@app.messaging.permit_connection "<self-id>"
```

Block connection from specific identity:
```ruby
@app.messaging.revoke_connection "<self-id>"
```

## Documentation

- [SDK documentation](https://www.rubydoc.info/gems/selfsdk)
- [General documentation](https://docs.joinself.com/)
- [Examples](examples)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

This project uses semantic versioning https://semver.org/. To create a new version run `bundle exec rake bump:(major|minor|patch)` depending on the version number you wish to increment. This will update the applications version as well as rebuild the dependencies to include the new version. Upon changes being merged into mainstream a new gem will be built, tagged and published to RubyGems.

### Developer commands

#### rake sources:generate

Generates the valid sources based on a json file (config/sources.json) instead of have them hardcoded on the gem.

## Support

Looking for help? Reach out to us at [support@joinself.zendesk.com](mailto:support@joinself.zendesk.com)

## Contributing

See [Contributing](CONTRIBUTING.md).

## License

See [License](LICENSE).
