# Copyright 2020 Self Group Ltd. All Rights Reserved.

module QrAuthentication
  class Runner
    def initialize(client, prompt)
      @client = client
      @prompt = prompt
    end

    def help
      <<-MSG
A Self user will be authenticated on your platform by
scanning a QR code and accepting the authentication
request on his phone.

As part of this process, you have to share the generated
QR code with your users, and wait for a response.
      MSG
    end

    # frozen_string_literal: true
    def run
      # printexample
      mutex = Mutex.new
      condvar = ConditionVariable.new

      # Register an observer for an authentication response
      @app.authentication.subscribe do |auth|
        # The user has rejected the authentication
        if !auth.accepted?
          puts "Authentication request has been rejected"
        else
          puts "User is now authenticated 🤘"
        end

        condvar.signal
      end

      # Generate a QR code to authenticate
      @app.authentication
          .generate_qr
          .as_png(border: 0, size: 400)
          .save('qr.png', :interlace => true)

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
