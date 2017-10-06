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

class Paginator
  attr_reader :items, :offset, :per_page, :total_items
  def initialize(items: [], offset: 0, per_page: 5, total_items: 0)
    @items, @offset, @per_page, @total_items = items, offset, per_page, total_items
  end

  def current_page
    offset / per_page + 1
  end

  def next_page?
    items_so_far < total_items
  end

  def previous_page?
    offset > 0
  end

  def items_so_far
    current_page * per_page - (per_page - items.size)
  end

  def next_offset
    offset + per_page
  end

  def previous_offset
    offset - per_page
  end
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
    store.zadd 'order_ids', 1, data[:id], nx: true
    data
  end

  def delete(id)
    store.del id
    store.zrem 'order_ids', id
  end

  def list(offset: 0, per_page: 5)
    offset = offset.to_i
    per_page = per_page.to_i
    total_items = store.zcard('order_ids')
    range = store.zrange('order_ids', offset, offset + per_page)
    items = range.map{|id| get(id) }

    Paginator.new(
      items: items,
      offset: offset,
      per_page: per_page,
      total_items: total_items
    )
  end

  private
  attr_reader :store
end

class Api < Sinatra::Base
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

    def update_order_status(id, status)
      data = repo.get(id)
      if data
        data[:status] = status
        repo.set data
        render data, Serializers::Order
      else
        render nil, Serializers::NotFound, 404
      end
    end
  end

  get '/?' do
    render nil, Serializers::Root
  end

  get '/orders' do
    list = repo.list(
      offset: params.fetch(:offset, 0).to_i,
      per_page: params.fetch(:per_page, 5)
    )

    render list, Serializers::Orders
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
    update_order_status id, 'placed'
  end

  put '/orders/:id/archive' do |id|
    update_order_status id, 'archived'
  end

  put '/orders/:id/completion' do |id|
    update_order_status id, 'completed'
  end
end
