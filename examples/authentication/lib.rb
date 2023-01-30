# Copyright 2020 Self Group Ltd. All Rights Reserved.
# frozen_string_literal: true

module Authentication
  class Runner
    def initialize(client, prompt)
      @client = client
      @prompt = prompt
    end

    def help
      <<-MSG
      Self provides a convenient way to authenticate users, this 
      specific example will send an authentication request to the
      provided user id.

      Bellow you'll need to introduce your user id to continue
      MSG
    end

    def run
      # printexample
      begin
        puts ""
        # Request the user id to be authenticated
        user_id = @prompt.ask("Please introduce the user id you want to authenticate: ") do |q|
          q.required true
        end

        mutex = Mutex.new
        condvar = ConditionVariable.new

        # Send an authentication request
        puts ""
        puts "we're sending an authentication reuqest to #{user_id}'s device"
        @client.authentication.request user_id do |auth_response|
          # The user has rejected the authentication
          if !auth_response.accepted?
            puts " - Authentication request has been rejected"
          else
            puts " - User is now authenticated 🤘"
          end
          condvar.signal
        end
      rescue => e
        # Raised exceptions usually happen because of requests timing out.
        puts "Oops! this is embarassing, but we found an error with your request"
        puts "#{e}"
        condvar.signal
      end
      mutex.synchronize do
        condvar.wait(mutex)
      end
      puts "DONE"
      # !printexample
    end
  end
end
