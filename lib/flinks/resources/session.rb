# frozen_string_literal: true

module Flinks
  module Resources
    class Session < Resource
      attribute :http_status_code, :integer
      attribute :institution_name, :string
      attribute :institution_id, :integer
      attribute :institution, :string
      attribute :request_id, :string

      attr_accessor :links, :login, :extra_attributes

      def initialize(attributes = {})
        @links = []
        @login = nil
        @extra_attributes = {}
        super
      end

      def attributes
        {
          "HttpStatusCode" => http_status_code,
          "Links" => links.map(&:attributes),
          "InstitutionName" => institution_name,
          "Login" => login&.attributes,
          "InstitutionId" => institution_id,
          "Institution" => institution,
          "RequestId" => request_id
        }.merge(extra_attributes)
      end

      def self.authorize(login_id:, most_recent_cached: true, authorize_token: )
        Flinks.client.authorize_session(login_id: login_id, most_recent_cached: most_recent_cached, authorize_token: authorize_token)
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when "HttpStatusCode" then "http_status_code"
        when "InstitutionName" then "institution_name"
        when "Links" then "links"
        when "Login" then "login"
        when "InstitutionId" then "institution_id"
        when "Institution" then "institution"
        when "RequestId" then "request_id"
        when "extra_attributes" then "extra_attributes"
        else
          key.to_s
        end
      end

      def attributes=(values)
        known_attributes = values.to_h.dup
        self.links = Array(known_attributes.delete("Links")).map do |link_attributes|
          Flinks::Resources::Link.new(link_attributes)
        end
        login_attributes = known_attributes.delete("Login")
        self.login = login_attributes ? Flinks::Resources::Login.new(login_attributes) : nil
        self.extra_attributes = known_attributes.reject do |key, _value|
          %w[HttpStatusCode InstitutionName InstitutionId Institution RequestId].include?(key.to_s)
        end
        super(known_attributes)
      end
    end
  end
end
