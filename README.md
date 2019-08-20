# Selfid::App

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
```
@app = Selfid::App.new("<my_app_id>", "<my_api_key>")
```

At this point your app should be able to send a login request.
```
uuid = @app.authenticate("<user_id>", "<callback_url>")
```

And check if the user has accepted the authentication request or not.
```
@app.authenticated?(response_body)
```

## Documentation

You can find documentation for this gem on https://aldgate-ventures.github.io/self-gem/

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aldgate-ventures/self-gem.


## License

The gem is available as open source under the terms of the [MIT License](LICENSE).
