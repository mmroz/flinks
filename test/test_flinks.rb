# frozen_string_literal: true

require "test_helper"

class TestFlinks < Minitest::Test
  def setup
    Flinks.iframe_url = "https://toolbox-wealth-iframe.private.fin.ag/v2/?demo=true"
    Flinks.api_url = "https://toolbox-api.private.fin.ag/"
    Flinks.customer_id = "43387ca6-0391-4c82-857d-70d95f087ecb"
    Flinks.bearer_token = "ze7ofYz28x1pxwrM"
    Flinks.flinks_auth_key = "c4569c54-e167-4d34-8de6-f4113bc82414"
    Flinks.x_api_key = "3980e499d84f4e04aea9a0b350be7a64"
    Flinks.log_level = nil
  end

  def test_that_it_has_a_version_number
    refute_nil ::Flinks::VERSION
  end

  def test_configuration_accessors
    assert_equal "https://toolbox-wealth-iframe.private.fin.ag/v2/?demo=true", Flinks.iframe_url
    assert_equal "https://toolbox-api.private.fin.ag/", Flinks.api_url
    assert_equal "43387ca6-0391-4c82-857d-70d95f087ecb", Flinks.customer_id
    assert_equal "ze7ofYz28x1pxwrM", Flinks.bearer_token
    assert_equal "c4569c54-e167-4d34-8de6-f4113bc82414", Flinks.flinks_auth_key
    assert_equal "3980e499d84f4e04aea9a0b350be7a64", Flinks.x_api_key
    assert_nil Flinks.log_level

    Flinks.iframe_url = "https://example.com/iframe"
    Flinks.api_url = "https://example.com/api"
    Flinks.customer_id = "customer-123"
    Flinks.bearer_token = "bearer-123"
    Flinks.flinks_auth_key = "auth-123"
    Flinks.x_api_key = "api-key-123"
    Flinks.log_level = :debug

    assert_equal "https://example.com/iframe", Flinks.iframe_url
    assert_equal "https://example.com/api", Flinks.api_url
    assert_equal "customer-123", Flinks.customer_id
    assert_equal "bearer-123", Flinks.bearer_token
    assert_equal "auth-123", Flinks.flinks_auth_key
    assert_equal "api-key-123", Flinks.x_api_key
    assert_equal :debug, Flinks.log_level
  end

  def test_client_post_logs_requests_when_debug_enabled
    Flinks.log_level = :debug
    response = Struct.new(:status, :body).new(
      200,
      {
        "HttpStatusCode" => 200,
        "Token" => "d65f1adb-8ebc-48dc-be8b-20c773ba1565"
      }.to_json
    )

    connection = Object.new
    connection.define_singleton_method(:post) do |_path, &block|
      request = Struct.new(:headers, :body).new({}, nil)
      block.call(request)
      response
    end

    output = nil

    Faraday.stub :new, connection do
      output, = capture_io do
        Flinks.client.generate_authorize_token
      end
    end

    assert_includes output, "[Flinks] POST https://toolbox-api.private.fin.ag/v3/43387ca6-0391-4c82-857d-70d95f087ecb/BankingServices/GenerateAuthorizeToken"
    assert_includes output, "[Flinks] Headers:"
    assert_includes output, "\"flinks-auth-key\"=>\"c4569c54-e167-4d34-8de6-f4113bc82414\""
    assert_includes output, "[Flinks] Body: (empty)"
  end

  def test_configure_yields_flinks_module
    Flinks.configure do |config|
      config.api_url = "https://configured.example/"
      config.customer_id = "configured-customer"
    end

    assert_equal "https://configured.example/", Flinks.api_url
    assert_equal "configured-customer", Flinks.customer_id
  end

  def test_client_uses_current_configuration
    Flinks.api_url = "https://configured.example/"
    Flinks.customer_id = "configured-customer"
    Flinks.flinks_auth_key = "configured-key"

    client = Flinks.client

    assert_equal "https://configured.example/v3/configured-customer/BankingServices/GenerateAuthorizeToken", client.generate_authorize_token_url
  end

  def test_authorize_token_success_payload
    resource = Flinks::Resources::AuthorizeToken.new(
      "HttpStatusCode" => 200,
      "Token" => "d65f1adb-8ebc-48dc-be8b-20c773ba1565"
    )

    assert_equal 200, resource.http_status_code
    assert_equal "d65f1adb-8ebc-48dc-be8b-20c773ba1565", resource.token
    assert_equal(
      {
        "HttpStatusCode" => 200,
        "Token" => "d65f1adb-8ebc-48dc-be8b-20c773ba1565"
      },
      resource.attributes
    )
  end

  def test_session_success_payload_builds_nested_resources
    resource = Flinks::Resources::Session.new(
      "HttpStatusCode" => 200,
      "Links" => [
        {
          "rel" => "AccountsDetail",
          "href" => "/GetAccountsDetail",
          "example" => nil
        },
        {
          "rel" => "AccountsSummary",
          "href" => "/GetAccountsSummary",
          "example" => nil
        }
      ],
      "InstitutionName" => "FlinksCapital",
      "Login" => {
        "Username" => "Greatday",
        "IsScheduledRefresh" => false,
        "LastRefresh" => "2026-01-21T20:47:47.145999",
        "Type" => "Personal",
        "Id" => "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
      },
      "InstitutionId" => 14,
      "Institution" => "FlinksCapital",
      "RequestId" => "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "AdditionalData" => "present"
    )

    assert_equal 200, resource.http_status_code
    assert_equal "FlinksCapital", resource.institution_name
    assert_equal 14, resource.institution_id
    assert_equal "FlinksCapital", resource.institution
    assert_equal "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", resource.request_id
    assert_equal 2, resource.links.length
    assert_instance_of Flinks::Resources::Link, resource.links.first
    assert_equal "AccountsDetail", resource.links.first.rel
    assert_equal "/GetAccountsDetail", resource.links.first.href
    assert_instance_of Flinks::Resources::Login, resource.login
    assert_equal "Greatday", resource.login.username
    refute resource.login.is_scheduled_refresh
    assert_equal "2026-01-21T20:47:47.145999", resource.login.last_refresh
    assert_equal "Personal", resource.login.type
    assert_equal "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx", resource.login.id
    assert_equal(
      {
        "AdditionalData" => "present"
      },
      resource.extra_attributes
    )
    assert_equal(
      {
        "HttpStatusCode" => 200,
        "Links" => [
          {
            "rel" => "AccountsDetail",
            "href" => "/GetAccountsDetail",
            "example" => nil
          },
          {
            "rel" => "AccountsSummary",
            "href" => "/GetAccountsSummary",
            "example" => nil
          }
        ],
        "InstitutionName" => "FlinksCapital",
        "Login" => {
          "Username" => "Greatday",
          "IsScheduledRefresh" => false,
          "LastRefresh" => "2026-01-21T20:47:47.145999",
          "Type" => "Personal",
          "Id" => "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        },
        "InstitutionId" => 14,
        "Institution" => "FlinksCapital",
        "RequestId" => "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "AdditionalData" => "present"
      },
      resource.attributes
    )
  end

  def test_account_summary_builds_accounts_links_and_login
    resource = Flinks::Resources::AccountSummary.new(
      "HttpStatusCode" => 200,
      "Accounts" => [
        {
          "EftEligibleRatio" => 0,
          "ETransferEligibleRatio" => 0,
          "Title" => "Primary Chequing Account",
          "AccountNumber" => "1234567",
          "LastFourDigits" => nil,
          "Balance" => {
            "Available" => 1234.45,
            "Current" => 4321.45,
            "Limit" => nil
          },
          "Category" => "Operations",
          "Type" => "Chequing",
          "Currency" => "CAD",
          "Holder" => {
            "Name" => "John Doe"
          },
          "AccountType" => "Personal",
          "Id" => "xxxx-xxxx-xxxxxxx-xxxxxx"
        }
      ],
      "Links" => [
        {
          "rel" => "AccountsDetail",
          "href" => "/GetAccountsDetail",
          "example" => nil
        }
      ],
      "Tag" => "userId=xxxxxxxxxxxx",
      "InstitutionName" => "BMO",
      "Login" => {
        "Username" => "1234567890",
        "IsScheduledRefresh" => false,
        "LastRefresh" => "2024-10-10T12:00:00.000000",
        "Type" => "Business",
        "Id" => "xxxx-xxxx-xxxxxx-xxxxxx"
      },
      "InstitutionId" => 1,
      "Institution" => "BMO",
      "RequestId" => "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx"
    )

    assert_equal 200, resource.http_status_code
    assert_equal "userId=xxxxxxxxxxxx", resource.tag
    assert_equal "BMO", resource.institution_name
    assert_equal 1, resource.institution_id
    assert_equal "BMO", resource.institution
    assert_equal "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxx", resource.request_id
    assert_instance_of Flinks::Resources::Account, resource.accounts.first
    assert_instance_of Flinks::Resources::Link, resource.links.first
    assert_instance_of Flinks::Resources::Login, resource.login
    assert_equal "Primary Chequing Account", resource.accounts.first.title
    assert_equal "/GetAccountsDetail", resource.links.first.href
    assert_equal "1234567890", resource.login.username
  end

  def test_account_detail_builds_success_payload
    resource = Flinks::Resources::AccountDetail.new(
      "HttpStatusCode" => 200,
      "Accounts" => [
        {
          "Transactions" => [
            {
              "Date" => "2025-01-31",
              "Code" => nil,
              "Description" => "PAYROLL - Stripe Paycheck",
              "Debit" => 1000.4,
              "Credit" => 1500.25,
              "Balance" => 5105.6,
              "Id" => "94584aed-7c98-42a4-9836-9f8557db63f5"
            }
          ],
          "Title" => "Chequing Account",
          "AccountNumber" => "7641238",
          "Id" => "27a9ffa0-c6b9-4cc6-9eaa-aa9efa07a889"
        }
      ],
      "InstitutionName" => "FlinksCapital",
      "Login" => {
        "Username" => "chat_gpt",
        "IsScheduledRefresh" => false,
        "LastRefresh" => "2025-01-31T17:40:54.569261",
        "Type" => "Personal",
        "Id" => "5602459c-f6d0-4ca0-6750-08dccdcadcc0"
      },
      "InstitutionId" => 14,
      "Institution" => "FlinksCapital",
      "RequestId" => "22178382-31ee-485c-a750-c20929b6a344"
    )

    assert_equal 200, resource.http_status_code
    assert_equal "FlinksCapital", resource.institution_name
    assert_equal 1, resource.accounts.length
    assert_instance_of Flinks::Resources::Account, resource.accounts.first
    assert_equal "Chequing Account", resource.accounts.first.title
    assert_instance_of Flinks::Resources::Transaction, resource.accounts.first.transactions.first
    assert_equal "2025-01-31", resource.accounts.first.transactions.first.date
    assert_instance_of Flinks::Resources::Login, resource.login
    assert_equal "chat_gpt", resource.login.username
  end

  def test_account_detail_pending_builds_pending_payload
    resource = Flinks::Resources::AccountDetailPending.new(
      "FlinksCode" => "OPERATION_PENDING",
      "Links" => [
        {
          "rel" => "{Endpoint}Async",
          "href" => "/{Endpoint}Async",
          "example" => "/{Endpoint}Async/{requestId}"
        }
      ],
      "HttpStatusCode" => 202,
      "Message" => "Your operation is still processing",
      "RequestId" => "077785a3-fd0f-42f7-9251-ee2ff7f3b4ff"
    )

    assert_equal 202, resource.http_status_code
    assert_equal "OPERATION_PENDING", resource.flinks_code
    assert_equal "Your operation is still processing", resource.message
    assert_equal "077785a3-fd0f-42f7-9251-ee2ff7f3b4ff", resource.request_id
    assert_equal 1, resource.links.length
    assert_instance_of Flinks::Resources::Link, resource.links.first
  end

  def test_get_accounts_detail_sends_expected_payload_and_returns_success_resource
    response = Struct.new(:status, :body).new(
      200,
      {
        "HttpStatusCode" => 200,
        "Accounts" => [
          {
            "Transactions" => [
              {
                "Date" => "2025-01-31",
                "Description" => "PAYROLL - Stripe Paycheck",
                "Id" => "txn-123"
              }
            ],
            "Title" => "Chequing Account",
            "Id" => "27a9ffa0-c6b9-4cc6-9eaa-aa9efa07a889"
          }
        ],
        "InstitutionName" => "FlinksCapital",
        "RequestId" => "22178382-31ee-485c-a750-c20929b6a344"
      }.to_json
    )

    captured_path = nil
    captured_headers = nil
    captured_body = nil
    connection = Object.new
    connection.define_singleton_method(:post) do |path, &block|
      captured_path = path
      request = Struct.new(:headers, :body).new({}, nil)
      block.call(request)
      captured_headers = request.headers
      captured_body = request.body
      response
    end

    Faraday.stub :new, connection do
      resource = Flinks.client.get_accounts_detail(request_id: "3fa391bc-bc52-4424-82c5-8662600df9b2")

      assert_instance_of Flinks::Resources::AccountDetail, resource
      assert_equal 200, resource.http_status_code
      assert_instance_of Flinks::Resources::Account, resource.accounts.first
      assert_equal "Chequing Account", resource.accounts.first.title
      assert_instance_of Flinks::Resources::Transaction, resource.accounts.first.transactions.first
      assert_equal "2025-01-31", resource.accounts.first.transactions.first.date
    end

    assert_equal "/v3/43387ca6-0391-4c82-857d-70d95f087ecb/BankingServices/GetAccountsDetail", captured_path
    assert_equal "application/json", captured_headers["Content-Type"]
    assert_equal Flinks.x_api_key, captured_headers["x-api-key"]
    assert_equal(
      {
        "RequestId" => "3fa391bc-bc52-4424-82c5-8662600df9b2",
        "WithAccountIdentity" => true,
        "WithKYC" => true,
        "WithTransactions" => true,
        "DaysOfTransactions" => "Days90",
        "WithDetailsAndBankingStatements" => false,
        "NumberOfBankingStatements" => "MostRecent"
      },
      JSON.parse(captured_body)
    )
  end

  def test_get_accounts_detail_returns_pending_resource_for_202
    response = Struct.new(:status, :body).new(
      202,
      {
        "FlinksCode" => "OPERATION_PENDING",
        "Links" => [
          {
            "rel" => "{Endpoint}Async",
            "href" => "/{Endpoint}Async",
            "example" => "/{Endpoint}Async/{requestId}"
          }
        ],
        "HttpStatusCode" => 202,
        "Message" => "Your operation is still processing",
        "RequestId" => "077785a3-fd0f-42f7-9251-ee2ff7f3b4ff"
      }.to_json
    )

    connection = Object.new
    connection.define_singleton_method(:post) do |_path, &block|
      request = Struct.new(:headers, :body).new({}, nil)
      block.call(request)
      response
    end

    Faraday.stub :new, connection do
      resource = Flinks.client.get_accounts_detail(request_id: "3fa391bc-bc52-4424-82c5-8662600df9b2")

      assert_instance_of Flinks::Resources::AccountDetailPending, resource
      assert_equal 202, resource.http_status_code
      assert_equal "077785a3-fd0f-42f7-9251-ee2ff7f3b4ff", resource.request_id
    end
  end

  def test_get_accounts_detail_async_returns_pending_resource_for_202
    response = Struct.new(:status, :body).new(
      202,
      {
        "FlinksCode" => "OPERATION_PENDING",
        "Links" => [
          {
            "rel" => "GetAccountsDetailAsync",
            "href" => "/GetAccountsDetailAsync",
            "example" => "/GetAccountsDetailAsync/077785a3-fd0f-42f7-9251-ee2ff7f3b4ff"
          }
        ],
        "HttpStatusCode" => 202,
        "Message" => "Your operation is still processing",
        "RequestId" => "077785a3-fd0f-42f7-9251-ee2ff7f3b4ff"
      }.to_json
    )

    captured_path = nil
    connection = Object.new
    connection.define_singleton_method(:get) do |path, &block|
      captured_path = path
      request = Struct.new(:headers).new({})
      block.call(request)
      response
    end

    Faraday.stub :new, connection do
      resource = Flinks.client.get_accounts_detail_async(request_id: "077785a3-fd0f-42f7-9251-ee2ff7f3b4ff")

      assert_instance_of Flinks::Resources::AccountDetailPending, resource
      assert_equal 202, resource.http_status_code
    end

    assert_equal "/v3/43387ca6-0391-4c82-857d-70d95f087ecb/BankingServices/GetAccountsDetailAsync/077785a3-fd0f-42f7-9251-ee2ff7f3b4ff", captured_path
  end

  def test_get_accounts_detail_async_returns_success_resource_with_login
    response = Struct.new(:status, :body).new(
      200,
      {
        "HttpStatusCode" => 200,
        "Accounts" => [
          {
            "Transactions" => [],
            "TransitNumber" => "12347",
            "InstitutionNumber" => "777",
            "Title" => "Chequing Account",
            "AccountNumber" => "7641238",
            "Balance" => {
              "Available" => 5405.5,
              "Current" => 5105.5,
              "Limit" => 5105.5
            },
            "Category" => "Operations",
            "Type" => "Chequing",
            "Currency" => "CAD",
            "Holder" => {
              "Name" => "Testing"
            },
            "AccountType" => nil,
            "Id" => "27a9ffa0-c6b9-4cc6-9eaa-aa9efa07a889"
          }
        ],
        "InstitutionName" => "FlinksCapital",
        "Login" => {
          "Username" => "chat_gpt",
          "IsScheduledRefresh" => false,
          "LastRefresh" => "2025-01-31T17:40:54.569261",
          "Type" => "Personal",
          "Id" => "5602459c-f6d0-4ca0-6750-08dccdcadcc0"
        },
        "InstitutionId" => 14,
        "Institution" => "FlinksCapital",
        "RequestId" => "22178382-31ee-485c-a750-c20929b6a344"
      }.to_json
    )

    connection = Object.new
    connection.define_singleton_method(:get) do |_path, &block|
      request = Struct.new(:headers).new({})
      block.call(request)
      response
    end

    Faraday.stub :new, connection do
      resource = Flinks.client.get_accounts_detail_async(request_id: "22178382-31ee-485c-a750-c20929b6a344")

      assert_instance_of Flinks::Resources::AccountDetail, resource
      assert_instance_of Flinks::Resources::Login, resource.login
      assert_equal "chat_gpt", resource.login.username
      assert_instance_of Flinks::Resources::Account, resource.accounts.first
      assert_equal "27a9ffa0-c6b9-4cc6-9eaa-aa9efa07a889", resource.accounts.first.id
    end
  end

  def test_account_detail_get_delegates_to_client
    client = Object.new
    expected_resource = Flinks::Resources::AccountDetailPending.new(
      "HttpStatusCode" => 202,
      "RequestId" => "req-123",
      "FlinksCode" => "OPERATION_PENDING",
      "Message" => "Your operation is still processing"
    )
    client.define_singleton_method(:get_accounts_detail) do |**kwargs|
      raise "unexpected kwargs" unless kwargs == {
        request_id: "req-123",
        with_account_identity: true,
        with_kyc: true,
        with_transactions: true,
        days_of_transactions: "Days90",
        with_details_and_banking_statements: false,
        number_of_banking_statements: "MostRecent"
      }

      expected_resource
    end

    Flinks.stub :client, client do
      resource = Flinks::AccountDetail.get(request_id: "req-123")

      assert_same expected_resource, resource
      assert_instance_of Flinks::Resources::AccountDetailPending, resource
    end
  end

  def test_account_detail_get_async_delegates_to_client
    client = Object.new
    expected_resource = Flinks::Resources::AccountDetail.new(
      "HttpStatusCode" => 200,
      "Accounts" => [
        {
          "Title" => "Chequing Account",
          "Id" => "acc-123"
        }
      ],
      "RequestId" => "req-123"
    )
    client.define_singleton_method(:get_accounts_detail_async) do |request_id:|
      raise "unexpected request_id" unless request_id == "req-123"

      expected_resource
    end

    Flinks.stub :client, client do
      resource = Flinks::AccountDetail.get_async(request_id: "req-123")

      assert_same expected_resource, resource
      assert_instance_of Flinks::Resources::AccountDetail, resource
    end
  end

  def test_generate_authorize_token_success
    response = Struct.new(:status, :body).new(
      200,
      {
        "HttpStatusCode" => 200,
        "Token" => "d65f1adb-8ebc-48dc-be8b-20c773ba1565"
      }.to_json
    )

    captured_path = nil
    captured_headers = nil
    connection = Object.new
    connection.define_singleton_method(:post) do |path, &block|
      captured_path = path
      request = Struct.new(:headers, :body).new({}, nil)
      block.call(request)
      captured_headers = request.headers
      response
    end

    Faraday.stub :new, connection do
      resource = Flinks::Resources::AuthorizeToken.generate

      assert_instance_of Flinks::Resources::AuthorizeToken, resource
      assert_equal 200, resource.http_status_code
      assert_equal "d65f1adb-8ebc-48dc-be8b-20c773ba1565", resource.token
    end

    assert_equal "/v3/43387ca6-0391-4c82-857d-70d95f087ecb/BankingServices/GenerateAuthorizeToken", captured_path
    assert_equal "application/json", captured_headers["Accept"]
    assert_equal "application/json", captured_headers["Content-Type"]
    assert_equal Flinks.flinks_auth_key, captured_headers["flinks-auth-key"]
  end

  def test_authorize_cached_session_success
    responses = [
      Struct.new(:status, :body).new(
        200,
        {
          "HttpStatusCode" => 200,
          "Token" => "generated-token"
        }.to_json
      ),
      Struct.new(:status, :body).new(
        200,
        {
          "HttpStatusCode" => 200,
          "Links" => [
            {
              "rel" => "AccountsDetail",
              "href" => "/GetAccountsDetail",
              "example" => nil
            }
          ],
          "InstitutionName" => "FlinksCapital",
          "Login" => {
            "Username" => "Greatday",
            "IsScheduledRefresh" => false,
            "LastRefresh" => "2026-01-21T20:47:47.145999",
            "Type" => "Personal",
            "Id" => "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
          },
          "InstitutionId" => 14,
          "Institution" => "FlinksCapital",
          "RequestId" => "req-123"
        }.to_json
      )
    ]
    captured_calls = []

    connection = Object.new
    connection.define_singleton_method(:post) do |path, &block|
      request = Struct.new(:headers, :body).new({}, nil)
      block.call(request)
      captured_calls << { path: path, headers: request.headers.dup, body: request.body }
      responses.shift
    end

    Faraday.stub :new, connection do
      resource = Flinks.client.authorize_cached_session(login_id: "login-123")

      assert_instance_of Flinks::Resources::Session, resource
      assert_equal 200, resource.http_status_code
      assert_equal "FlinksCapital", resource.institution_name
      assert_equal "req-123", resource.request_id
      assert_instance_of Flinks::Resources::Link, resource.links.first
      assert_instance_of Flinks::Resources::Login, resource.login
    end

    assert_equal 2, captured_calls.length
    assert_equal "/v3/43387ca6-0391-4c82-857d-70d95f087ecb/BankingServices/GenerateAuthorizeToken", captured_calls[0][:path]
    assert_equal "/v3/43387ca6-0391-4c82-857d-70d95f087ecb/BankingServices/Authorize", captured_calls[1][:path]
    assert_equal "generated-token", captured_calls[1][:headers]["flinks-auth-key"]
    assert_equal "Bearer ze7ofYz28x1pxwrM", captured_calls[1][:headers]["Authorization"]
    assert_equal "{\"LoginId\":\"login-123\",\"MostRecentCached\":true}", captured_calls[1][:body]
  end

  def test_get_accounts_summary_success
    response = Struct.new(:status, :body).new(
      200,
      {
        "HttpStatusCode" => 200,
        "Accounts" => [
          {
            "Title" => "Primary Chequing Account",
            "Id" => "xxxx-xxxx-xxxxxxx-xxxxxx"
          }
        ],
        "Links" => [
          {
            "rel" => "AccountsDetail",
            "href" => "/GetAccountsDetail",
            "example" => nil
          }
        ],
        "Tag" => "userId=xxxxxxxxxxxx",
        "InstitutionName" => "BMO",
        "Login" => {
          "Username" => "1234567890",
          "IsScheduledRefresh" => false,
          "LastRefresh" => "2024-10-10T12:00:00.000000",
          "Type" => "Business",
          "Id" => "xxxx-xxxx-xxxxxx-xxxxxx"
        },
        "InstitutionId" => 1,
        "Institution" => "BMO",
        "RequestId" => "request-123"
      }.to_json
    )
    captured_call = nil

    connection = Object.new
    connection.define_singleton_method(:post) do |path, &block|
      request = Struct.new(:headers, :body).new({}, nil)
      block.call(request)
      captured_call = { path: path, headers: request.headers.dup, body: request.body }
      response
    end

    Faraday.stub :new, connection do
      resource = Flinks.client.get_accounts_summary(request_id: "request-123")

      assert_instance_of Flinks::Resources::AccountSummary, resource
      assert_equal 200, resource.http_status_code
      assert_instance_of Flinks::Resources::Account, resource.accounts.first
      assert_instance_of Flinks::Resources::Link, resource.links.first
      assert_instance_of Flinks::Resources::Login, resource.login
    end

    assert_equal "/v3/43387ca6-0391-4c82-857d-70d95f087ecb/BankingServices/GetAccountsSummary", captured_call[:path]
    assert_equal "3980e499d84f4e04aea9a0b350be7a64", captured_call[:headers]["x-api-key"]
    assert_equal "application/json", captured_call[:headers]["Accept"]
    assert_equal "application/json", captured_call[:headers]["Content-Type"]
    assert_equal(
      "{\"RequestId\":\"request-123\",\"WithBalance\":true,\"WithAccountIdentity\":true}",
      captured_call[:body]
    )
  end

  def test_authorize_cached_session_raises_on_authorize_token_error
    response = Struct.new(:status, :body).new(
      401,
      {
        "HttpStatusCode" => 401,
        "Message" => "You must provide a valid auth key",
        "FlinksCode" => "UNAUTHORIZED"
      }.to_json
    )

    connection = Object.new
    connection.define_singleton_method(:post) do |_path, &block|
      request = Struct.new(:headers, :body).new({}, nil)
      block.call(request)
      response
    end

    Faraday.stub :new, connection do
      error = assert_raises(Flinks::Error) do
        Flinks.client.authorize_cached_session(login_id: "login-123")
      end

      assert_equal 401, error.error_object.http_status_code
      assert_equal "UNAUTHORIZED", error.error_object.flinks_code
    end
  end

  def test_generate_authorize_token_uses_current_configuration
    client = Flinks::Client.new(
      api_url: "https://example.com/custom-api/",
      customer_id: "customer-override"
    )

    assert_equal(
      "https://example.com/custom-api/v3/customer-override/BankingServices/GenerateAuthorizeToken",
      client.generate_authorize_token_url
    )
  end

  def test_generate_authorize_token_raises_on_error
    response = Struct.new(:status, :body).new(
      401,
      {
        "HttpStatusCode" => 401,
        "Message" => "You must provide a valid auth key",
        "FlinksCode" => "UNAUTHORIZED"
      }.to_json
    )

    connection = Object.new
    connection.define_singleton_method(:post) do |_path, &block|
      request = Struct.new(:headers, :body).new({}, nil)
      block.call(request)
      response
    end

    Faraday.stub :new, connection do
      error = assert_raises(Flinks::Error) do
        Flinks::Resources::AuthorizeToken.generate
      end

      assert_equal 401, error.error_object.http_status_code
      assert_equal "You must provide a valid auth key", error.error_object.message
      assert_equal "UNAUTHORIZED", error.error_object.flinks_code
    end
  end

  def test_error_object_error_payload
    resource = Flinks::Resources::ErrorObject.from_json(
      {
        "HttpStatusCode" => 401,
        "Message" => "You must provide a valid auth key",
        "FlinksCode" => "UNAUTHORIZED"
      }.to_json
    )

    assert_equal 401, resource.http_status_code
    assert_equal "You must provide a valid auth key", resource.message
    assert_equal "UNAUTHORIZED", resource.flinks_code
    assert_equal(
      {
        "HttpStatusCode" => 401,
        "Message" => "You must provide a valid auth key",
        "FlinksCode" => "UNAUTHORIZED"
      },
      resource.attributes
    )
  end

  def test_webhook_authentication_from_url
    resource = Flinks::Resources::Webhook::Authentication.from_url(
      "https://example.com/flinks/connect/callback?demo=true&loginId=181fb102-48de-44b9-de78-08de7b4f854b&institution=FlinksCapital&requestId=req-123&redirect=/done"
    )

    assert_equal "true", resource.demo
    assert_equal "181fb102-48de-44b9-de78-08de7b4f854b", resource.login_id
    assert_equal "FlinksCapital", resource.institution
    assert_equal(
      {
        "requestId" => "req-123",
        "redirect" => "/done"
      },
      resource.extra_query_params
    )
  end

  def test_webhook_authentication_attributes_include_extra_query_params
    resource = Flinks::Resources::Webhook::Authentication.new(
      "demo" => "true",
      "loginId" => "181fb102-48de-44b9-de78-08de7b4f854b",
      "institution" => "FlinksCapital",
      "extra_query_params" => { "requestId" => "req-123" }
    )

    assert_equal(
      {
        "demo" => "true",
        "loginId" => "181fb102-48de-44b9-de78-08de7b4f854b",
        "institution" => "FlinksCapital",
        "requestId" => "req-123"
      },
      resource.attributes
    )
  end

  def test_get_accounts_detail_raises_session_nonexistent_error
    response = Struct.new(:status, :body).new(
      400,
      {
        "HttpStatusCode" => 400,
        "Message" => "RequestId 1df20baf-65d5-40ee-9be0-8058c13042e2 is invalid or session has ended",
        "FlinksCode" => "SESSION_NONEXISTENT"
      }.to_json
    )

    connection = Object.new
    connection.define_singleton_method(:post) do |_path, &block|
      request = Struct.new(:headers, :body).new({}, nil)
      block.call(request)
      response
    end

    Faraday.stub :new, connection do
      error = assert_raises(Flinks::SessionNonexistentError) do
        Flinks.client.get_accounts_detail(request_id: "1df20baf-65d5-40ee-9be0-8058c13042e2")
      end

      assert_instance_of Flinks::Resources::SessionNonexistentErrorObject, error.error_object
      assert_equal 400, error.error_object.http_status_code
      assert_equal "SESSION_NONEXISTENT", error.error_object.flinks_code
      assert_equal "RequestId 1df20baf-65d5-40ee-9be0-8058c13042e2 is invalid or session has ended", error.error_object.message
    end
  end
end
