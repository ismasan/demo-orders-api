require "oat"
require 'oat/adapters/hal'

module Serializers
  class BaseAdapter < Oat::Adapters::HAL
    def items(collection, serializer_class = nil, &block)
      entities :items, collection, serializer_class, &block
    end
  end

  class Base < Oat::Serializer
    adapter BaseAdapter

    private
    def url(*args)
      context[:helper].url(*args)
    end
  end
end
