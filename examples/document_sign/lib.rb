# Copyright 2020 Self Group Ltd. All Rights Reserved.
# frozen_string_literal: true

module DocumentSign
  class Runner
    def initialize(client, prompt)
      @client = client
      @prompt = prompt
    end

    def help
      <<-MSG
      MSG
    end

    def run
      # printexample
      mutex = Mutex.new
      condvar = ConditionVariable.new

      puts ""
      user = @prompt.ask("Please introduce the user id you want to request a signature:") do |q|
        q.required true
      end

      @app.docs.request_signature user, terms, objects do |resp|
        if resp.status == 'accepted'
          puts "Document signed!".green
          puts ''
          puts 'signed documents: '

          resp.signed_objects.each do |so|
            puts "- Name:  #{so[:name]}"
            puts "  Link:  #{so[:link]}"
            puts "  Hash:  #{so[:hash]}"
          end
          puts ''
          puts "full signature:"
          puts resp.input
        else
          puts "Document signature #{'rejected'.red}"
        end

        mutex.synchronize do
          condvar.signal
        end
      end

      mutex.synchronize do
        condvar.wait(mutex)
      end
      # !printexample
    end
  end
end
