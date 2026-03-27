# frozen_string_literal: true

module Flinks
  module Resources
    class Account < Resource
      attribute :eft_eligible_ratio
      attribute :e_transfer_eligible_ratio
      attribute :transactions
      attribute :transit_number, :string
      attribute :institution_number, :string
      attribute :overdraft_limit
      attribute :title, :string
      attribute :account_number, :string
      attribute :last_four_digits, :string
      attribute :balance
      attribute :category, :string
      attribute :type, :string
      attribute :currency, :string
      attr_accessor :holder
      attribute :account_type, :string
      attribute :id, :string
      attr_accessor :extra_attributes

      def initialize(attributes = {})
        @extra_attributes = {}
        super
      end

      def attributes
        {
          "EftEligibleRatio" => eft_eligible_ratio,
          "ETransferEligibleRatio" => e_transfer_eligible_ratio,
          "Transactions" => transactions,
          "TransitNumber" => transit_number,
          "InstitutionNumber" => institution_number,
          "OverdraftLimit" => overdraft_limit,
          "Title" => title,
          "AccountNumber" => account_number,
          "LastFourDigits" => last_four_digits,
          "Balance" => balance,
          "Category" => category,
          "Type" => type,
          "Currency" => currency,
          "Holder" => holder&.attributes,
          "AccountType" => account_type,
          "Id" => id
        }.merge(extra_attributes)
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when "EftEligibleRatio" then "eft_eligible_ratio"
        when "ETransferEligibleRatio" then "e_transfer_eligible_ratio"
        when "Transactions" then "transactions"
        when "TransitNumber" then "transit_number"
        when "InstitutionNumber" then "institution_number"
        when "OverdraftLimit" then "overdraft_limit"
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
        when "extra_attributes" then "extra_attributes"
        else
          key.to_s
        end
      end

      def attributes=(values)
        known_attributes = values.to_h.dup
        transaction_attributes = known_attributes.delete("Transactions")
        self.transactions = Array(transaction_attributes).map do |transaction_attributes|
          Flinks::Resources::Transaction.new(transaction_attributes)
        end if transaction_attributes
        holder_attributes = known_attributes.delete("Holder")
        self.holder = holder_attributes ? Flinks::Resources::AccountHolder.new(holder_attributes) : nil
        self.extra_attributes = known_attributes.reject do |key, _value|
          %w[
            EftEligibleRatio
            ETransferEligibleRatio
            TransitNumber
            InstitutionNumber
            OverdraftLimit
            Title
            AccountNumber
            LastFourDigits
            Balance
            Category
            Type
            Currency
            Holder
            AccountType
            Id
          ].include?(key.to_s)
        end
        super(known_attributes)
      end
    end
  end
end
