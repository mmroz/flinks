# frozen_string_literal: true

require "active_model"
require "faraday"
require "json"
require_relative "flinks/version"
require_relative "flinks/client"
require_relative "flinks/resources/resource"
require_relative "flinks/resources/error_object"
require_relative "flinks/resources/session_nonexistent_error_object"
require_relative "flinks/resources/authorize_token"
require_relative "flinks/resources/account"
require_relative "flinks/resources/transaction"
require_relative "flinks/resources/account_detail"
require_relative "flinks/resources/account_detail_pending"
require_relative "flinks/resources/account_summary"
require_relative "flinks/resources/link"
require_relative "flinks/resources/login"
require_relative "flinks/resources/session"
require_relative "flinks/resources/webhook/authentication"

module Flinks
  class Error < StandardError
    attr_reader :error_object

    def initialize(error_object)
      @error_object = error_object
      super(build_message(error_object))
    end

    private

    def build_message(error_object)
      parts = []
      parts << "HTTP #{error_object.http_status_code}" if error_object.respond_to?(:http_status_code) && error_object.http_status_code
      parts << error_object.flinks_code if error_object.respond_to?(:flinks_code) && error_object.flinks_code
      parts << error_object.message if error_object.respond_to?(:message) && error_object.message
      parts.empty? ? "Flinks API error" : parts.join(": ")
    end
  end

  class SessionNonexistentError < Error
  end

  class << self
    attr_accessor :iframe_url,
                  :api_url,
                  :customer_id,
                  :bearer_token,
                  :flinks_auth_key,
                  :x_api_key,
                  :log_level
  end

  self.iframe_url = "https://toolbox-iframe.private.fin.ag/"
  self.api_url = "https://toolbox-api.private.fin.ag/"
  self.customer_id = "43387ca6-0391-4c82-857d-70d95f087ecb"
  self.bearer_token = "ze7ofYz28x1pxwrM"
  self.flinks_auth_key = "c4569c54-e167-4d34-8de6-f4113bc82414"
  self.x_api_key = "3d5266a8-b697-48d4-8de6-52e2e2662acc"
  self.log_level = :debug

  def self.client
    Client.new
  end


  def self.configure
    yield self
  end

  module Resources
  end

  AuthorizeToken = Resources::AuthorizeToken
  ErrorObject = Resources::ErrorObject
  SessionNonexistentErrorObject = Resources::SessionNonexistentErrorObject
  Account = Resources::Account
  Transaction = Resources::Transaction
  AccountDetail = Resources::AccountDetail
  AccountDetailPending = Resources::AccountDetailPending
  AccountSummary = Resources::AccountSummary
  Link = Resources::Link
  Login = Resources::Login
  Session = Resources::Session
  WebhookAuthentication = Resources::Webhook::Authentication
end
