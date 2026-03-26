# frozen_string_literal: true

module Flinks
  module Resources
    class Transaction < Resource
      attribute :date, :string
      attribute :code, :string
      attribute :description, :string
      attribute :debit
      attribute :credit
      attribute :balance
      attribute :id, :string
      attribute :category, :string
      attribute :sub_category, :string

      attr_accessor :extra_attributes

      def initialize(attributes = {})
        @extra_attributes = {}
        super
      end

      def attributes
        {
          "Date" => date,
          "Code" => code,
          "Description" => description,
          "Debit" => debit,
          "Credit" => credit,
          "Balance" => balance,
          "Id" => id,
          "Category" => category,
          "SubCategory" => sub_category
        }.merge(extra_attributes)
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when "Date" then "date"
        when "Code" then "code"
        when "Description" then "description"
        when "Debit" then "debit"
        when "Credit" then "credit"
        when "Balance" then "balance"
        when "Id" then "id"
        when "Category" then "category"
        when "SubCategory" then "sub_category"
        when "extra_attributes" then "extra_attributes"
        else
          key.to_s
        end
      end

      def attributes=(values)
        known_attributes = values.to_h.dup
        self.extra_attributes = known_attributes.reject do |key, _value|
          %w[Date Code Description Debit Credit Balance Id Category SubCategory].include?(key.to_s)
        end
        super(known_attributes)
      end
    end
  end
end
