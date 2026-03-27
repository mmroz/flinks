# frozen_string_literal: true

module Flinks
  module Resources
    class Link < Resource
      attribute :rel, :string
      attribute :href, :string
      attribute :example

      def attributes
        {
          'rel' => rel,
          'href' => href,
          'example' => example
        }
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when 'rel' then 'rel'
        when 'href' then 'href'
        when 'example' then 'example'
        else
          key.to_s
        end
      end
    end
  end
end
