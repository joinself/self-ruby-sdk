# Copyright 2020 Self Group Ltd. All Rights Reserved.

module DlAuthentication
  class Runner
    def initialize(client, prompt)
      @client = client
      @prompt = prompt
    end

    def help
      <<-MSG
      MSG
    end

    # frozen_string_literal: true
    def run
      # printexample
      mutex = Mutex.new
      condvar = ConditionVariable.new

      puts "In order to use dynamic links, you need to create a redirection code"
      puts "through the Self developer portal."
      puts "In order to do so, go to the main menu (on the left) and under your app"
      puts "click redirections and create a new redirection"
      puts ""

      # You can manage your redirection codes on your app management on the
      # developer portal
      redirection_code = @prompt.ask("Please introduce redirection code you've created:") do |q|
        q.required true
      end

      # Register an observer for an authentication response
      puts ""
      puts "setting up a subscription for authentications"
      @client.authentication.subscribe do |auth|
        # The user has rejected the authentication
        if auth.accepted?
          puts "User is now authenticated 🤘"
        else
          puts "Authentication request has been rejected"
        end

        mutex.synchronize do
          condvar.signal
        end
      end

      # Generate a DL code to authenticate
      url = @client.authentication.generate_deep_link(redirection_code)
      puts "All done, please authenticate through this link: "
      puts url

      mutex.synchronize do
        condvar.wait(mutex)
      end
      # !printexample
    end
  end
end
