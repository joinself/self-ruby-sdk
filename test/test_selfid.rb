require 'minitest/autorun'
require 'selfid'

require 'webmock/minitest'
require 'timecop'

class SelfidTest < Minitest::Test
  def setup
    t = Time.local(2019, 9, 1, 10, 5, 0)
    Timecop.travel(t)
  end
  def teardown
    Timecop.return
  end

  def test_init_with_defaults
    app = Selfid::App.new("my_app_id", "my_api_key", "my_auth_token")
    assert_equal "https://api.selfid.net", app.self_url
    assert_equal "my_app_id", app.app_id
    assert_equal "my_api_key", app.api_key
    assert_equal "my_auth_token", app.auth_token
  end

  def test_init_with_custom_parameters
    app = Selfid::App.new("my_app_id", "my_api_key", "my_auth_token", self_url: "http://custom.self.net")
    assert_equal "http://custom.self.net", app.self_url
    assert_equal "my_app_id", app.app_id
    assert_equal "my_api_key", app.api_key
    assert_equal "my_auth_token", app.auth_token
  end

  def test_authenticate
    stub_request(:post, "http://api.selfid.net:443/auth").
      with(
        body: '{"payload":"eyJjYWxsYmFjayI6Imh0dHA6Ly9sb2NhbGhvc3Q6MzAwMC9jYWxsYmFjayIs\nInVybCI6Imh0dHBzOi8vYXBpLnNlbGZpZC5uZXQiLCJzZWxmX2lkIjoibXlf\nYXBwX2lkIiwidXNlcl9pZCI6Inh4eHh4eHh4IiwiY3JlYXRlZCI6IjIwMTkt\nMDktMDEgMTA6MDU6MDAgKzAyMDAiLCJleHBpcmVzIjoiMjAxOS0wOS0wMSAx\nMTowNTowMCArMDIwMCIsIlVVSUQiOiJ1dWlkIn0=\n","protected":"eyJ0eXAiOiJFZERTQSJ9\n","signature":"LlN4Fsu6Zjpyg8kSgduw8bOzvQsFhKMk9MewIHTKdquKda5LEKm30zZF2Ane\nvunYxdG8GzRLcAuF5bXKw5JZBA==\n"}',
        headers: {
      	  'Accept'=>'*/*',
      	  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      	  'Authorization'=>'Bearer my_auth_token',
      	  'Content-Type'=>'application/json',
      	  'User-Agent'=>'Ruby'
        }).
      to_return(status: 200, body: "", headers: {})

    seed = "\x86x4\x8E\xA5'\x11\xE9\xEB\x04\xD1\x1C\xD0O\xFC\xBCox;(m\x89\xC1N;Yb5\xD5\x9B\x11\x9A"
    app = Selfid::App.new("my_app_id", seed, "my_auth_token")
    app.authenticate("xxxxxxxx", "http://localhost:3000/callback", uuid: "uuid")
    assert_requested :post, "http://api.selfid.net:443/auth",
      headers: {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Bearer my_auth_token', 'Content-Type'=>'application/json', 'User-Agent'=>'Ruby'},
      body: '{"payload":"eyJjYWxsYmFjayI6Imh0dHA6Ly9sb2NhbGhvc3Q6MzAwMC9jYWxsYmFjayIs\nInVybCI6Imh0dHBzOi8vYXBpLnNlbGZpZC5uZXQiLCJzZWxmX2lkIjoibXlf\nYXBwX2lkIiwidXNlcl9pZCI6Inh4eHh4eHh4IiwiY3JlYXRlZCI6IjIwMTkt\nMDktMDEgMTA6MDU6MDAgKzAyMDAiLCJleHBpcmVzIjoiMjAxOS0wOS0wMSAx\nMTowNTowMCArMDIwMCIsIlVVSUQiOiJ1dWlkIn0=\n","protected":"eyJ0eXAiOiJFZERTQSJ9\n","signature":"LlN4Fsu6Zjpyg8kSgduw8bOzvQsFhKMk9MewIHTKdquKda5LEKm30zZF2Ane\nvunYxdG8GzRLcAuF5bXKw5JZBA==\n"}',
      times: 1    # ===> Success
  end
end
