# bundle exec ruby hypermedia-console.rb
require 'bootic_client'
require 'bootic_client/strategies/strategy'
config = Struct.new(:api_root).new('https://demo-orders-api.herokuapp.com/')
CLIENT = BooticClient::Strategies::Strategy.new(config)
