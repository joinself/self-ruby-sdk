# Copyright 2020 Self Group Ltd. All Rights Reserved.

module Voice
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
      # Request display_name and email_address to the specified user
      begin
        @client.voice.on_start do |issuer, payload|
          # Redirect the call to a second user
          puts "[app] received start from #{issuer}, redirecting..."
          @client.voice.start customer, payload[:cid], payload[:call_id], payload[:peer_info], { operator_name: "Supu" }
        end

        @client.voice.on_accept do |issuer, payload|
          puts "[app] received acceptation from #{issuer}, redirecting..."
          @client.voice.accept operator, payload[:cid], payload[:call_id], payload[:peer_info]
        end

        @client.voice.on_stop do |issuer, payload|
          puts "[app] received stop from #{issuer}, redirecting..."
          if issuer == operator
            puts "[app] ... to customer"
            @client.voice.stop customer, payload[:cid], payload[:call_id]
          else
            puts "[app] ... to operator"
            @client.voice.stop operator, payload[:cid], payload[:call_id]
          end
        end

        @client.voice.on_busy do |issuer, payload|
          puts "[app] received busy from #{issuer}, redirecting..."
          if issuer == operator
            @client.voice.busy customer, payload[:cid], payload[:call_id]
          else
            @client.voice.busy operator, payload[:cid], payload[:call_id]
          end
        end

        puts "[app] sending setup request to #{operator}"
        @client.voice.setup(operator, "Bob", "cid")
      rescue => e
        puts "ERROR : #{e}"
        exit!
      end
      # !printexample
    end
  end
end
