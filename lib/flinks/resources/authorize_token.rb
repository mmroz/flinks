# frozen_string_literal: true

module Flinks
  module Resources
    class AuthorizeToken < Resource
      attribute :http_status_code, :integer
      attribute :token, :string

      def attributes
        {
          'HttpStatusCode' => http_status_code,
          'Token' => token
        }
      end

      def self.generate
        Flinks.client.generate_authorize_token
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when 'HttpStatusCode' then 'http_status_code'
        when 'Token' then 'token'
        else
          key.to_s
        end
      end
    end
  end
end
