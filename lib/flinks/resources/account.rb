# frozen_string_literal: true

module Flinks
  module Resources
    class Account < Resource
      attribute :eft_eligible_ratio
      attribute :e_transfer_eligible_ratio
      attribute :title, :string
      attribute :account_number, :string
      attribute :last_four_digits, :string
      attribute :balance
      attribute :category, :string
      attribute :type, :string
      attribute :currency, :string
      attribute :holder
      attribute :account_type, :string
      attribute :id, :string

      def attributes
        {
          "EftEligibleRatio" => eft_eligible_ratio,
          "ETransferEligibleRatio" => e_transfer_eligible_ratio,
          "Title" => title,
          "AccountNumber" => account_number,
          "LastFourDigits" => last_four_digits,
          "Balance" => balance,
          "Category" => category,
          "Type" => type,
          "Currency" => currency,
          "Holder" => holder,
          "AccountType" => account_type,
          "Id" => id
        }
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when "EftEligibleRatio" then "eft_eligible_ratio"
        when "ETransferEligibleRatio" then "e_transfer_eligible_ratio"
        when "Title" then "title"
        when "AccountNumber" then "account_number"
        when "LastFourDigits" then "last_four_digits"
        when "Balance" then "balance"
        when "Category" then "category"
        when "Type" then "type"
        when "Currency" then "currency"
        when "Holder" then "holder"
        when "AccountType" then "account_type"
        when "Id" then "id"
        else
          key.to_s
        end
      end
    end
  end
end
