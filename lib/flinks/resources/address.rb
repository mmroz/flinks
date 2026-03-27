# frozen_string_literal: true

module Flinks
  module Resources
    class Address < Resource
      attribute :civic_address, :string
      attribute :city, :string
      attribute :province, :string
      attribute :postal_code, :string
      attribute :po_box, :string
      attribute :country, :string
      attr_accessor :extra_attributes

      def initialize(attributes = {})
        @extra_attributes = {}
        super
      end

      def attributes
        {
          "CivicAddress" => civic_address,
          "City" => city,
          "Province" => province,
          "PostalCode" => postal_code,
          "POBox" => po_box,
          "Country" => country
        }.merge(extra_attributes)
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when "CivicAddress" then "civic_address"
        when "City" then "city"
        when "Province" then "province"
        when "PostalCode" then "postal_code"
        when "POBox" then "po_box"
        when "Country" then "country"
        when "extra_attributes" then "extra_attributes"
        else
          key.to_s
        end
      end

      def attributes=(values)
        known_attributes = values.to_h.dup
        self.extra_attributes = known_attributes.reject do |key, _value|
          %w[CivicAddress City Province PostalCode POBox Country].include?(key.to_s)
        end
        super(known_attributes)
      end
    end
  end
end
