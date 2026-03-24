# frozen_string_literal: true

module Flinks
  class Client
    def initialize(
      api_url: Flinks.api_url,
      customer_id: Flinks.customer_id,
      flinks_auth_key: Flinks.flinks_auth_key,
      bearer_token: Flinks.bearer_token,
      x_api_key: Flinks.x_api_key
    )
      @api_url = api_url
      @customer_id = customer_id
      @flinks_auth_key = flinks_auth_key
      @bearer_token = bearer_token
      @x_api_key = x_api_key
    end

    def generate_authorize_token
      post(
        "#{banking_services_base_url}/GenerateAuthorizeToken",
        headers: {
          "Accept" => "application/json",
          "Content-Type" => "application/json",
          "flinks-auth-key" => @flinks_auth_key
        },
        resource_class: Flinks::Resources::AuthorizeToken
      )
    end

    def authorize_session(login_id:, most_recent_cached:, authorize_token:)
      token = generate_authorize_token

      post(
        "#{banking_services_base_url}/Authorize",
        headers: {
          "flinks-auth-key" => token.token,
          "Authorization" => bearer_authorization
        },
        json: {
          LoginId: login_id,
          MostRecentCached: true,
          authorizeToken: authorize_token,
        },
        resource_class: Flinks::Resources::Session
      )
    end

    def get_accounts_summary(request_id:, with_balance: true, with_account_identity: true)
      post(
        "#{banking_services_base_url}/GetAccountsSummary",
        headers: {
          "x-api-key" => @x_api_key
        },
        json: {
          RequestId: request_id,
          WithBalance: with_balance,
          WithAccountIdentity: with_account_identity
        },
        resource_class: Flinks::Resources::AccountSummary
      )
    end

    def generate_authorize_token_url
      "#{banking_services_base_url}/GenerateAuthorizeToken"
    end

    private

    def connection
      @connection ||= Faraday.new(url: @api_url)
    end

    def banking_services_base_url
      "/v3/#{@customer_id}/BankingServices"
    end

    def bearer_authorization
      "Bearer #{@bearer_token}"
    end

    def post(path_or_url, headers: {}, json: nil, resource_class:)
      request_body = json ? JSON.generate(json) : nil
      request_headers = { "Accept" => "application/json" }.merge(headers)
      request_headers["Content-Type"] = "application/json" if json

      log_request(
        method: "POST",
        url: absolute_url(path_or_url),
        headers: request_headers,
        body: request_body
      )

      response = connection.post(path_or_url) do |request|
        request.headers["Accept"] ||= "application/json"
        headers.each do |header, value|
          request.headers[header] = value
        end
        if json
          request.headers["Content-Type"] ||= "application/json"
          request.body = request_body
        end
      end

      payload = self.class.parse_response_body(response.body)
      payload["HttpStatusCode"] ||= response.status

      build_response_object(response.status, payload, resource_class)
    end

    def build_response_object(status, payload, resource_class)
      if status.between?(200, 299)
        resource_class.new(payload)
      else
        error_object = Flinks::Resources::ErrorObject.new(payload)
        raise Flinks::Error.new(error_object)
      end
    end

    def self.parse_response_body(body)
      return {} if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      { "Message" => body.to_s }
    end

    def log_request(method:, url:, headers:, body:)
      return unless debug_logging_enabled?

      puts "[Flinks] #{method} #{url}"
      puts "[Flinks] Headers: #{headers.inspect}"
      puts "[Flinks] Body: #{body || '(empty)'}"
    end

    def debug_logging_enabled?
      Flinks.log_level.to_s.downcase == "debug"
    end

    def absolute_url(path_or_url)
      return path_or_url if path_or_url.start_with?("http://", "https://")

      "#{@api_url.to_s.chomp('/')}#{path_or_url}"
    end
  end
end
