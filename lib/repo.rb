require 'securerandom'
class Repo
  def initialize(store, &notifier)
    @store = store
    @notifier = block_given? ? notifier : ->(chanel, data){}
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

    notifier.call(:updates, data)

    data
  end

  def delete(id)
    store.del id
    store.zrem 'order_ids', id
    notifier.call(:deletes, {id: id})
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
  attr_reader :store, :notifier
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

