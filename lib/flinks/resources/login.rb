# frozen_string_literal: true

module Flinks
  module Resources
    class Login < Resource
      attribute :username, :string
      attribute :is_scheduled_refresh, :boolean
      attribute :last_refresh, :string
      attribute :type, :string
      attribute :id, :string

      def attributes
        {
          'Username' => username,
          'IsScheduledRefresh' => is_scheduled_refresh,
          'LastRefresh' => last_refresh,
          'Type' => type,
          'Id' => id
        }
      end

      def self.normalize_attribute_name(key)
        case key.to_s
        when 'Username' then 'username'
        when 'IsScheduledRefresh' then 'is_scheduled_refresh'
        when 'LastRefresh' then 'last_refresh'
        when 'Type' then 'type'
        when 'Id' then 'id'
        else
          key.to_s
        end
      end
    end
  end
end
