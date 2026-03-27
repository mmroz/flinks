# frozen_string_literal: true

module Flinks
  module Resources
    class AccountHolder < Resource
      attribute :name, :string
      attribute :email, :string
      attribute :phone_number, :string
      attr_accessor :address, :extra_attributes

      def initialize(attributes = {})
        @address = nil
        @extra_attributes = {}
        super
      end

      def attributes
        {
          "Name" => name,
          "Address" => address&.attributes,
          "Email" => email,
          "PhoneNumber" => phone_number
        }.merge(extra_attributes)
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when "Name" then "name"
        when "Address" then "address"
        when "Email" then "email"
        when "PhoneNumber" then "phone_number"
        when "extra_attributes" then "extra_attributes"
        else
          key.to_s
        end
      end

      def attributes=(values)
        known_attributes = values.to_h.dup
        address_attributes = known_attributes.delete("Address")
        self.address = address_attributes ? Flinks::Resources::Address.new(address_attributes) : nil
        self.extra_attributes = known_attributes.reject do |key, _value|
          %w[Name Address Email PhoneNumber].include?(key.to_s)
        end
        super(known_attributes)
      end
    end
  end
end
