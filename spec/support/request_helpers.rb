require 'bootic_client'
require "bootic_client/strategies/bearer"
require_relative '../../api'

module RequestHelpers
  ClientConfig = Struct.new(:api_root)

  def app
    Api
  end

  def client
    BooticClient::Strategies::Bearer.new(
      ClientConfig.new(
        "http://example.org"
      ),
      access_token: 'abc',
      faraday_adapter: [:rack, app]
    )
  end

  def root
    client.root
  end
end
