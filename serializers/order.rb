require_relative './base'
module Serializers
  class Order < Base
    schema do
      link :self, href: url("/orders/#{item[:id]}")
      if item[:status] == 'placed'
        link :archive_order, href: url("/orders/#{item[:id]}/archive"), method: :put, title: "archive this order"
        link :complete_order, href: url("/orders/#{item[:id]}/completion"), method: :put, title: "complete this order"
      end
      if item[:status] == 'open'
        link :add_line_item, href: url("/orders/#{item[:id]}/line_items"), method: :post, title: "add a line item"
        link :delete_order, href: url("/orders/#{item[:id]}"), method: :delete, title: "delete this order"
        link :place_order, href: url("/orders/#{item[:id]}/placement"), method: :put, title: "place this order"
      end

      property :id, item[:id]
      property :status, item[:status]
      property :total, item[:total]
      property :created_on, item[:created_on]
      property :updated_on, item[:updated_on]

      order = item
      entities :line_items, (item[:line_items] || []) do |it, s|
        if order[:status] == 'open'
          s.link :delete_line_item, href: url("/orders/#{order[:id]}/line_items/#{it[:id]}"), method: :delete
        end
        s.properties do |props|
          props.id it[:id]
          props.name it[:name]
          props.units it[:units]
          props.price it[:price]
        end
      end
    end
  end
end
