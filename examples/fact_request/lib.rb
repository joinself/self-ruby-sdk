# Copyright 2020 Self Group Ltd. All Rights Reserved.
# frozen_string_literal: true

module FactRequest
  class Runner
    def initialize(client, prompt)
      @client = client
      @prompt = prompt
    end

    def help
      <<-MSG
Your app can request certain bits of information to your 
connected users. To do this, you'll only need its _SelfID_
and the fields you want to request you can find a list of
updated valid fields [here](https://github.com/selfid-net/selfid-gem/blob/main/lib/sources.rb).

Due of its nature the information request is an asynchronous
process, where your program should wait for user's input before
processing the response. This process is fully managed by
`request_information` gem function.
      MSG
    end

    def run
      # printexample
      begin
        puts ""
        # Request the user id to send a fact request to
        user_id = @prompt.ask("Please introduce the user id you want to send a fact request to: ") do |q|
          q.required true
        end

        mutex = Mutex.new
        condvar = ConditionVariable.new

        # Send an fact request
        puts ""
        puts "we're sending an fact reuqest to #{user_id}'s device"
        @client.facts.request(user, [:display_name, :email_address]) do |res|
          # Information request has been rejected by the user
          if res.status == "rejected"
            puts 'Information request rejected'
            condvar.signal
          end

          # Response comes in form of facts easy to access with facts method
          attestations = res.attestation_values_for(:display_name).join(", ")
          puts "Hello #{attestations}!"
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
