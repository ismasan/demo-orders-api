require_relative './base'
module Serializers
  class Errors < Base
    schema do
      property :message, "invalid entity"
      property :errors, item
    end
  end
end
