# frozen_string_literal: true

module Flinks
  module Resources
    class AccountDetailPending < Resource
      attribute :http_status_code, :integer
      attribute :flinks_code, :string
      attribute :message, :string
      attribute :request_id, :string

      attr_accessor :links, :extra_attributes, :login

      def initialize(attributes = {})
        @links = []
        @login = nil
        @extra_attributes = {}
        super
      end

      def attributes
        {
          'FlinksCode' => flinks_code,
          'Links' => links.map(&:attributes),
          'HttpStatusCode' => http_status_code,
          'Message' => message,
          'RequestId' => request_id,
          'Login' => login&.attributes
        }.merge(extra_attributes)
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when 'FlinksCode' then 'flinks_code'
        when 'Links' then 'links'
        when 'HttpStatusCode' then 'http_status_code'
        when 'Message' then 'message'
        when 'RequestId' then 'request_id'
        when 'extra_attributes' then 'extra_attributes'
        when 'Login' then 'login'
        else
          key.to_s
        end
      end

      def attributes=(values)
        known_attributes = values.to_h.dup
        self.links = Array(known_attributes.delete('Links')).map do |link_attributes|
          Flinks::Resources::Link.new(link_attributes)
        end
        login_attributes = known_attributes.delete('Login')
        self.login = login_attributes ? Flinks::Resources::Login.new(login_attributes) : nil
        self.extra_attributes = known_attributes.reject do |key, _value|
          %w[FlinksCode HttpStatusCode Message RequestId].include?(key.to_s)
        end
        super(known_attributes)
      end
    end
  end
end
