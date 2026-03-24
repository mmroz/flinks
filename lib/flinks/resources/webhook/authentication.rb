# frozen_string_literal: true

require "cgi"
require "uri"

module Flinks
  module Resources
    module Webhook
      class Authentication < Resource
        attribute :demo, :string
        attribute :login_id, :string
        attribute :institution, :string

        attr_accessor :extra_query_params

        def initialize(attributes = {})
          @extra_query_params = {}
          super
        end

        def attributes
          {
            "demo" => demo,
            "loginId" => login_id,
            "institution" => institution
          }.merge(extra_query_params)
        end

        def self.from_url(url)
          uri = URI.parse(url)
          params = parse_query(uri.query.to_s)

          new(
            "demo" => params["demo"],
            "loginId" => params["loginId"],
            "institution" => params["institution"],
            "extra_query_params" => params.reject { |key, _value| %w[demo loginId institution].include?(key) }
          )
        end

        def self.normalize_attribute_name(key)
          case key.to_s
          when "demo" then "demo"
          when "loginId" then "login_id"
          when "institution" then "institution"
          when "extra_query_params" then "extra_query_params"
          else
            key.to_s
          end
        end

        def self.parse_query(query)
          CGI.parse(query).each_with_object({}) do |(key, values), params|
            params[key] = values.length == 1 ? values.first : values
          end
        end
        private_class_method :parse_query
      end
    end
  end
end
