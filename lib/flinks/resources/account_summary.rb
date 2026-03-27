# frozen_string_literal: true

module Flinks
  module Resources
    class AccountSummary < Resource
      attribute :http_status_code, :integer
      attribute :tag, :string
      attribute :institution_name, :string
      attribute :institution_id, :integer
      attribute :institution, :string
      attribute :request_id, :string

      attr_accessor :accounts, :links, :login, :extra_attributes

      def initialize(attributes = {})
        @accounts = []
        @links = []
        @login = nil
        @extra_attributes = {}
        super
      end

      def attributes
        {
          'HttpStatusCode' => http_status_code,
          'Accounts' => accounts.map(&:attributes),
          'Links' => links.map(&:attributes),
          'Tag' => tag,
          'InstitutionName' => institution_name,
          'Login' => login&.attributes,
          'InstitutionId' => institution_id,
          'Institution' => institution,
          'RequestId' => request_id
        }.merge(extra_attributes)
      end

      def self.get(request_id:, with_balance: true, with_account_identity: true)
        Flinks.client.get_accounts_summary(
          request_id: request_id,
          with_balance: with_balance,
          with_account_identity: with_account_identity
        )
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when 'HttpStatusCode' then 'http_status_code'
        when 'Accounts' then 'accounts'
        when 'Links' then 'links'
        when 'Tag' then 'tag'
        when 'InstitutionName' then 'institution_name'
        when 'Login' then 'login'
        when 'InstitutionId' then 'institution_id'
        when 'Institution' then 'institution'
        when 'RequestId' then 'request_id'
        when 'extra_attributes' then 'extra_attributes'
        else
          key.to_s
        end
      end

      def attributes=(values)
        known_attributes = values.to_h.dup
        self.accounts = Array(known_attributes.delete('Accounts')).map do |account_attributes|
          Flinks::Resources::Account.new(account_attributes)
        end
        self.links = Array(known_attributes.delete('Links')).map do |link_attributes|
          Flinks::Resources::Link.new(link_attributes)
        end
        login_attributes = known_attributes.delete('Login')
        self.login = login_attributes ? Flinks::Resources::Login.new(login_attributes) : nil
        self.extra_attributes = known_attributes.reject do |key, _value|
          %w[HttpStatusCode Tag InstitutionName InstitutionId Institution RequestId].include?(key.to_s)
        end
        super(known_attributes)
      end
    end
  end
end
