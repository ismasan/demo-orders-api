require 'securerandom'
require 'json'
require 'redis'
require 'sinatra/base'
require 'parametric'

module Serializers

end

Dir["./serializers/*.rb"].each do |f|
  require f
end

ItemSchema = Parametric::Schema.new do
  field(:name).type(:string).present
  field(:price).type(:integer).default(100)
  field(:units).type(:integer).default(1)
end

REDIS = Redis.new(url: ENV.fetch('REDIS_URL'))

class Repo
  def initialize(store)
    @store = store
  end

  def get(id)
    data = store.get(id)
    data ? JSON.parse(data, symbolize_names: true) : nil
  end

  def set(data)
    data[:id] = SecureRandom.hex unless data[:id]
    data[:created_on] = Time.now.iso8601 unless data[:created_on]
    data[:updated_on] = Time.now.iso8601

    store.set(data[:id], JSON.dump(data))
    data
  end

  def delete(id)
    store.del id
  end

  private
  attr_reader :store
end

class App < Sinatra::Base
  helpers do
    def render(item, serializer, st = 200)
      content_type "application/json"
      halt(
        st,
        JSON.dump(serializer.new(item, helper: self).to_hash),
      )
    end

    def repo
      @repo ||= Repo.new(REDIS)
    end

    def json_data
      @json_data ||= JSON.parse(request.body.read, symbolize_names: true)
    end

    def recalculate(order)
      order[:total] = order[:line_items].reduce(0){|sum, it| sum + it[:price] * it[:units]}
      order
    end

    def add_item(order, item)
      item[:id] = SecureRandom.hex
      item[:created_on] = Time.now.iso8601
      (order[:line_items] ||= []) << item
      recalculate order
    end

    def delete_item(order, item_id)
      order[:line_items].delete_if{|it| it[:id] == item_id}
      recalculate order
    end
  end

  get '/?' do
    render nil, Serializers::Root
  end

  post '/orders' do
    data = repo.set({status: 'open', total: 0, line_items: []})
    render data, Serializers::Order, 201
  end

  get '/orders/:id' do |id|
    data = repo.get(id)
    if data
      render data, Serializers::Order
    else
      render nil, Serializers::NotFound, 404
    end
  end

  delete '/orders/:id' do |id|
    repo.delete  id
    halt 204, ""
  end

  post '/orders/:id/line_items' do |id|
    data = repo.get(id)
    if data
      item = ItemSchema.resolve(json_data)
      if item.errors.any?
        render item.errors, Serializers::Errors, 422
      else
        data = add_item(data, item.output)
        repo.set(data)
      end
      render data, Serializers::Order
    else
      render nil, Serializers::NotFound, 404
    end
  end

  delete '/orders/:id/line_items/:item_id' do |id, item_id|
    data = repo.get(id)
    if data
      data = delete_item(data, item_id)
      repo.set data
      render data, Serializers::Order
    else
      render nil, Serializers::NotFound, 404
    end
  end

  put '/orders/:id/placement' do |id|
    data = repo.get(id)
    if data
      data[:status] = 'placed'
      repo.set data
      render data, Serializers::Order
    else
      render nil, Serializers::NotFound, 404
    end
  end
end
