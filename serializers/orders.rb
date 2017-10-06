require_relative './base'
require_relative './order'
module Serializers
  class Orders < Base
    schema do
      link :self, href: url("/orders?offset=#{item.offset}&per_page=#{item.per_page}")
      if item.next_page?
        link :next, href: url("/orders?offset=#{item.next_offset}&per_page=#{item.per_page}")
      end
      if item.previous_page?
        link :previous, href: url("/orders?offset=#{item.previous_offset}&per_page=#{item.per_page}")
      end

      property :page, item.current_page
      property :offset, item.offset
      property :per_page, item.per_page
      property :total_items, item.total_items

      items item.items, Order
    end

    def has_next_page?(list)
      page = (list.offset / item.per_page) + 1
      items_so_far = page * item.per_page - (item.per_page - item.items.size)
      items_so_far < list.total_items
    end
  end
end
