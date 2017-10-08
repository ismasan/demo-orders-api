require_relative './base'
module Serializers
  class Root < Base
    schema do
      link :self, href: url
      link :orders, href: url('/orders'), title: 'list all orders'
      link :order, href: url("/orders/{id}"), templated: true, title: "get a single order by ID"
      link :create_order, href: url('/orders'), method: :post, title: 'create a new order'
    end
  end
end
