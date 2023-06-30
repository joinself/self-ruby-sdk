require_relative '../../lib/selfsdk'

def setup(app_id, device_id, storage_key)
  SelfSDK.logger = ::Logger.new($stdout).tap do |log|
    log.progname = "SelfSDK examples"
  end if ENV.has_key?'SELF_LOGS'

  # You can point to a different environment by passing optional values to the initializer
  opts = ENV.has_key?('SELF_ENV') ? { env: ENV["SELF_ENV"] } : {}
  storage_dir = "#{File.expand_path("..", File.dirname(__FILE__))}/self_storage"

  # Connect your app to Self network, get your connection details creating a new
  # app on https://developer.selfsdk.net/
  SelfSDK::App.new(app_id, 
                   device_id, 
                   storage_key, 
                   storage_dir,
                   opts)
end

puts "1. start app sdk &&  2. publish app prekeys"
oldapp = setup(ENV["SELF_APP_ID"], ENV["SELF_APP_DEVICE_SECRET"], ENV["STORAGE_KEY"]).start

puts "3. close app sdk"
oldapp.close
sleep 5

puts "4. start app sdk"
@newapp = setup(ENV["SELF_APP_ID"], ENV["SELF_APP_DEVICE_SECRET"], ENV["STORAGE_KEY"])
sleep 5
@newapp.chat.on_message do |msg|
  puts "......."
  puts "......."
  puts "7. app decrypt message #{msg.body}"
  puts "......."
  puts "......."
  puts msg.body
end
@newapp.start
# TODO: if I move the subscription to after the start, it does not work WTF!!!!!

puts "5. start client sdk"
client = setup(ENV["CLIENT_SELF_APP_ID"], ENV["CLIENT_SELF_APP_DEVICE_SECRET"], ENV["STORAGE_KEY"]).start

sleep 5
puts "6. client create session with app"
client.chat.message(ENV["SELF_APP_ID"], "hi")

sleep 9999999

