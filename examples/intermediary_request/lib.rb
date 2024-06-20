# Copyright 2020 Self Group Ltd. All Rights Reserved.
# frozen_string_literal: true

module IntermediaryRequest
  class Runner
    def initialize(client, prompt)
      @client = client
      @prompt = prompt
    end

    def help
      <<-MSG
A zero knowledge information request allows you do assertions
on user's facts through _Self Intermediary_ without direct
access to user's information.

This prevents users to leak sensible information with untrusted
peers and keep the trust on the platform.
      MSG
    end

    def run
      # printexample
      begin
        puts ""
        # Request the user id to send a fact request to
        user = @prompt.ask("Please introduce the user id you want to send a fact request to: ") do |q|
          q.required true
        end

        # Even its a silly test lets check if the user's email is equal test@test.org
        # without ever leaking information about the user's fact.
        res_opts = {}
        res_opts[:intermediary] = ENV['SELF_INTERMEDIARY'] if ENV.has_key?('SELF_INTERMEDIARY')
        res = @app.facts.request_via_intermediary(user, [{ sources: [:user_specified],
                                                           fact: :email_address,
                                                           operator: :equals,
                                                           expected_value: 'test@test.org' }], res_opts)

        if res.nil? # The request can timeout
          p "Request has timed out"
        elsif res.accepted? # The user accepts the intermediary request
          p "Request has been accepted"
          p "Your assertion is #{res.attestation(:email_address).value}"
        elsif res.rejected? # The user rejects the intermediary request
          p "Request has been rejected"
        elsif res.unauthorized? # You're not a connection for the specified user
          p "You're not authorized to interact with this user"
        elsif res.errored? # An error occured
          p "An error occured"
        end
      rescue => e
        # Raised exceptions usually happen because of requests timing out.
        puts "Oops! this is embarassing, but we found an error with your request"
        puts "#{e}"
        condvar.signal
      end

      # !printexample
    end
  end
end
