class SelfidTest < Minitest::Test
  describe "information" do
    def test_dummy
      stub_request(:get, "https://api.selfid.net/v1/identities/a6d48192f2342b9520def84e595f9fcd/devices").
        with(
          headers: {
      	  'Authorization'=>'Bearer eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJpc3MiOiI0YzkxNTQ3MDE4ZGZjMjlhODBlZTFiNGQ4NjU5MDNiZiJ9.k6TvlPeMdzJ2Z-TeTPgTxvPdAGXyOWMZN54Dfo-Q-Ht2C0mENlADfJ45Q0PbueLwazpHlI3z6XDqn_wLKCbwCQ',
      	  'Content-Type'=>'application/json'
          }).
        to_return(status: 200, body: '[{"id":"1","token":""}]', headers: {})

      # invalid input
      john_id = "4c91547018dfc29a80ee1b4d865903bf"
      john_seed = "5B50YAsu4PudPf2+FHQ0JuQUN/I2Yi6naR2y557bK/g"
      steff_id = "a6d48192f2342b9520def84e595f9fcd"
      steff_seed = "jUVhvO7FjKJDmbdr3wmXbfuD04v4JzaqxFTx6oszETE"

      @steff = Selfid::App.new(steff_id, steff_seed)
      @john = Selfid::App.new(john_id, john_seed)

      @steff.connect(john_id)
      @john.connect(steff_id)

      Thread.new do
        p "john is requesting information"
        @john.request_information(steff_id, ["a","b","c"], type: :async)
      end
      sleep 10
      require 'pry'; binding.pry
      p "stef getting unread messages"
      @steff.inbox.each do |m|

      end
      sleep 20000
    ensure
      @steff.stop
      @john.stop
    end
  end
end
