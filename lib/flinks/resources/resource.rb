# frozen_string_literal: true

require 'pp'

module Flinks
  module Resources
    class Resource
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Serializers::JSON

      def initialize(attributes = {})
        super()
        self.attributes = attributes if attributes
      end

      def attributes=(values)
        values.to_h.each do |key, value|
          attribute_name = self.class.normalize_attribute_name(key)
          writer = "#{attribute_name}="
          public_send(writer, value) if respond_to?(writer)
        end
      end

      def self.from_json(json)
        new.tap { |resource| resource.from_json(json) }
      end

      def self.normalize_attribute_name(key)
        key.to_s
      end

      def inspect
        "#<#{self.class.name} #{formatted_attributes}>"
      end

      def pretty_print(printer)
        printer.text(inspect)
      end

      private

      def formatted_attributes
        attributes.map { |key, value| "#{key}=#{value.inspect}" }.join(', ')
      end
    end
  end
end
