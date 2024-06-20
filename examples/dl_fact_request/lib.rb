# Copyright 2020 Self Group Ltd. All Rights Reserved.
# frozen_string_literal: true

module DlFactRequest
  class Runner
    def initialize(client, prompt)
      @client = client
      @prompt = prompt
    end

    def help
      <<-MSG
Your app can request certain bits of information to your connected
users via Deep Link. To do this, you'll only need its _SelfID_ and
the fields you want to request you can find a list of updated valid
fields
      MSG
    end

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
      @client.messaging.subscribe :fact_response do |res|
        # Information request has been rejected by the user
        if res.status == "accepted"
          # Response comes in form of facts easy to access with facts method
          puts "Retrieved facts : #{res.attestation(:display_name).value}!"
        else
          puts 'Information request rejected'
        end

        mutex.synchronize do
          condvar.signal
        end
      end

      # Generate a DL code to share facts
      url = @client.authentication.generate_deep_link(redirection_code)
      puts "All setup, please share facts through this link: "
      puts url

      mutex.synchronize do
        condvar.wait(mutex)
      end
      # !printexample
    end
  end
end
