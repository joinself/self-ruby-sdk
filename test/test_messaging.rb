class SelfidTest < Minitest::Test
  describe "information" do
    let(:seed)      { ENV['APP_KEY'] }
    let(:app_id)    { ENV["APP_ID"] }
    let(:app)       { Selfid::App.new(app_id, seed) }

    def test_dummy
      # invalid input
      res = app.request_information(app_id, ["a","b","c"])
    end
  end
end
