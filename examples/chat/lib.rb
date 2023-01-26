# Copyright 2020 Self Group Ltd. All Rights Reserved.

module Chat
  class Runner
    def initialize(client, prompt)
      @client = client
      @prompt = prompt
    end

    def help
      <<-MSG
      This example allows your app to interact with a user through a
      chat conversation.

      You must introduce your user id to continue
      MSG
    end

    # frozen_string_literal: true
    def run
      # printexample
      puts ""
      user = @prompt.ask("Please introduce the user id you want to chat with:") do |q|
        q.required true
      end

      # Send a "hi" message to a specific user
      puts "- I'm sending a 'hi' message to your device"
      @client.chat.message(user, "hi")

      # Setup a hook for any incoming messages
      puts "- I'm setting up a listener for any incoming messages"
      puts ""
      puts "Please, send a message from your device to continue."
      mutex = Mutex.new
      condvar = ConditionVariable.new

      @client.chat.on_message do |msg|
        # Once a message is received we will
        puts "- Message received : #{msg.body.green}"
        puts ""

        # 1. Mark it as delivered
        puts " 1.- I'm now marking the message as delivered"
        msg.mark_as_delivered

        # 2. Mark it as read
        puts " 2.- And now as read!"
        msg.mark_as_read

        # 3. Send a direct response to that message.
        puts " 3.- I'm sending a direct response back to your original message"
        msg.respond("hi!")

        # 4. Send a regular message to the same conversation
        puts " 4.- Now I'm sending another message, and waiting 2 seconds before editing it"
        resp = msg.message("howre you doin?")
        sleep 2

        # 5. Edit the previously sent message
        puts " 5.- I'm sending a modification of the original message, and waiting 3 seconds"
        resp.edit("how're you doing?")
        sleep 3

        # 6. delete already sent message
        puts " 6.- Now I'm deleting the original message"
        resp.delete!

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
