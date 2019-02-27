require 'minitest/autorun'
require 'rack/test'
require 'sinatra'
require File.expand_path '../../app/hello_world.rb', __FILE__

class MyTest < MiniTest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_hello_world
    get '/'
    assert last_response.ok?
    hello_world = ENV['HELLO_WORLD'] || 'Hello World!'
    assert_equal hello_world, last_response.body
  end
end
