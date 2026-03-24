# frozen_string_literal: true

module Flinks
  module Resources
    class ErrorObject < Resource
      attribute :http_status_code, :integer
      attribute :message, :string
      attribute :flinks_code, :string

      def attributes
        {
          "HttpStatusCode" => http_status_code,
          "Message" => message,
          "FlinksCode" => flinks_code
        }
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when "HttpStatusCode" then "http_status_code"
        when "Message" then "message"
        when "FlinksCode" then "flinks_code"
        else
          key.to_s
        end
      end
    end
  end
end
