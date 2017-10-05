require_relative './base'
module Serializers
  class NotFound < Base
    schema do
      link :root, href: url("/"), title: "back to the root"

      property :message, "resource not found"
    end
  end
end
