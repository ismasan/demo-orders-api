require_relative 'api'
require_relative 'web'

App = Rack::Builder.new do
  map "/dashboard" do
    run Web
  end

  run Api
end

run App
