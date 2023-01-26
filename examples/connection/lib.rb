# Copyright 2020 Self Group Ltd. All Rights Reserved.

module Connection
  class Runner
    def initialize(client, prompt)
      @client = client
      @prompt = prompt
    end

    def help
      <<-MSG
      Self provides a convenient way to for your users to find and 
      connect to your app.

      In this example we will explore how you can subscribe to those 
      subscriptions, and send back a welcome message.
      MSG
    end

    # frozen_string_literal: true
    def run
      # printexample
      mutex = Mutex.new
      condvar = ConditionVariable.new

      # Register an observer for a connection response
      @client.chat.on_connection do |res|
        if res.status == "accepted"
          puts "successfully connected"
          @client.chat.message(res.from, "Hey there! We're connected!")
        end
        condvar.signal
      end

      # Generate a QR code for the connection request
      @client.chat
             .generate_connection_qr
             .as_png(border: 0, size: 400)
             .save('qr.png', interlace: true)

      # This will open the exported qr.png with your default software,
      # manually open /tmp/qr.png and scan it with your device if it
      # does not work
      puts "Open and scan ./examples/qr.png with your device"

      mutex.synchronize do
        condvar.wait(mutex)
      end
      puts "DONE".green
      # !printexample
    end
  end
end
