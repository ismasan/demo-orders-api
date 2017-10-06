require 'sinatra/base'
require_relative 'api'

class Web < Sinatra::Base
  helpers do

  end

  get '/?' do
    erb :dashboard
  end
end
