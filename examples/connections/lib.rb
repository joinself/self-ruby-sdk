# Copyright 2020 Self Group Ltd. All Rights Reserved.

module Connections
  class Runner
    def initialize(client, prompt)
      @client = client
      @prompt = prompt
    end

    def help
      <<-MSG
      Self provides ways to protect yourself from spam, or 
      simply limit the people who has access to your app.

      This limits can be managed by permitting or revoking 
      connections by self identifier.

      This example plays around with the ACL hepers.
      MSG
    end

    # frozen_string_literal: true
    def run
      # printexample
      # Remove all existing connections
      connections = @client.messaging.allowed_connections
      puts 'List existing connections'
      puts " - connections : #{connections.join(',')}"

      # Block connections from *
      puts 'Block all connections'
      @client.messaging.revoke_connection("*")

      # List should be empty
      connections = @client.messaging.allowed_connections
      puts " - connections : #{connections.join(',')}"

      # Allow connections from 1112223334
      puts 'Permit connections from a specific ID'
      user_id = @prompt.ask("Please provide the user id you want to permit: ") do |q|
        q.required true
      end

      @client.messaging.permit_connection(user_id)
      connections = @client.messaging.allowed_connections
      puts " - connections : #{connections.join(',')}"

      # Allow connections from *
      puts 'Permit all connections (replaces all other entries with a wildcard entry)'
      @client.messaging.permit_connection("*")
      connections = @client.messaging.allowed_connections
      puts " - connections : #{connections.join(',')}"
      puts ''

      # Allow connections from 1112223334
      puts 'Permit connection from a specific ID' 
      puts '(nothing will change as the list already contains a wildcard entry)'
      @client.messaging.permit_connection(user_id)
      connections = @client.messaging.allowed_connections
      puts " - connections : #{connections.join(',')}"
      puts ''

      # Allow connections from *
      puts 'Allow all connections'
      @client.messaging.permit_connection('*')
      # !printexample
    end
  end
end
