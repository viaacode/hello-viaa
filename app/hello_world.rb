require 'sinatra'

set :bind, '0.0.0.0'

get '/' do
  hello_world = ENV['HELLO_WORLD'] || 'Hello World!'
  puts hello_world
  hello_world
end
