# Flinks

Ruby client and resource models for a Flinks banking integration.

This project wraps a small set of Flinks endpoints with:

- a configurable `Flinks::Client`
- `ActiveModel`-based resource objects
- nested models for structured API responses
- webhook URL parsing for the connect callback flow

## Current Scope

The gem currently supports:

- `GenerateAuthorizeToken`
- `Authorize` with `MostRecentCached: true`
- `GetAccountsSummary`
- webhook callback parsing for `/flinks/connect/callback`

## Installation

From the project directory:

```bash
bundle install
```

To load the gem in an interactive Ruby session:

```bash
cd ~/Desktop/flinks
bundle exec irb -I lib -r flinks
```

## Configuration

The gem exposes module-level configuration on `Flinks`:

```ruby
Flinks.iframe_url
Flinks.api_url
Flinks.customer_id
Flinks.bearer_token
Flinks.flinks_auth_key
Flinks.x_api_key
```

You can configure it directly:

```ruby
Flinks.api_url = "https://toolbox-api.private.fin.ag/"
Flinks.customer_id = "43387ca6-0391-4c82-857d-70d95f087ecb"
Flinks.bearer_token = "your-bearer-token"
Flinks.flinks_auth_key = "your-flinks-auth-key"
Flinks.x_api_key = "your-x-api-key"
```

Or via a block:

```ruby
Flinks.configure do |config|
  config.api_url = "https://toolbox-api.private.fin.ag/"
  config.customer_id = "43387ca6-0391-4c82-857d-70d95f087ecb"
  config.bearer_token = "your-bearer-token"
  config.flinks_auth_key = "your-flinks-auth-key"
  config.x_api_key = "your-x-api-key"
end
```

## Client Usage

Create a client from the current module config:

```ruby
client = Flinks.client
```

Or instantiate one explicitly:

```ruby
client = Flinks::Client.new(
  api_url: "https://toolbox-api.private.fin.ag/",
  customer_id: "43387ca6-0391-4c82-857d-70d95f087ecb",
  flinks_auth_key: "your-flinks-auth-key",
  bearer_token: "your-bearer-token",
  x_api_key: "your-x-api-key"
)
```

### Generate Authorize Token

```ruby
response = Flinks.client.generate_authorize_token
response.class
response.attributes
```

Successful responses return `Flinks::Resources::AuthorizeToken`.

Error responses return `Flinks::Resources::ErrorObject`.

### Authorize Session

This calls `/Authorize` and returns a `Flinks::Session`.

Usage:

```ruby
session = Flinks::Session.authorize(
  login_id: "login-id",
  authorize_token: "authorize-token"
)
session.class
session.attributes
```

Request body:

```json
{
  "LoginId": "...",
  "MostRecentCached": true,
  "authorizeToken": "..."
}
```

### Get Accounts Summary

This calls `/GetAccountsSummary` with the configured `x-api-key`.

Usage:

```ruby
summary = Flinks::AccountSummary.get(request_id: "request-id")
summary.class
summary.attributes
```

Optional flags:

```ruby
summary = Flinks::AccountSummary.get(
  request_id: "request-id",
  with_balance: true,
  with_account_identity: true
)
```

## Resource Models

All API models inherit from `Flinks::Resources::Resource` and use:

- `ActiveModel::Model`
- `ActiveModel::Attributes`
- `ActiveModel::Serializers::JSON`

Current resources:

- `Flinks::AuthorizeToken`
- `Flinks::ErrorObject`
- `Flinks::Session`
- `Flinks::AccountSummary`
- `Flinks::Account`
- `Flinks::Link`
- `Flinks::Login`
- `Flinks::WebhookAuthentication`

Resources implement a custom `inspect`, so in `irb` they print readable attribute output instead of a raw object id.

## Session Shape

`Flinks::Resources::Session` models:

- `http_status_code`
- `links`
- `institution_name`
- `login`
- `institution_id`
- `institution`
- `request_id`

`links` is an array of `Flinks::Resources::Link`.

`login` is a `Flinks::Resources::Login`.

## Account Summary Shape

`Flinks::Resources::AccountSummary` models:

- `http_status_code`
- `accounts`
- `links`
- `tag`
- `institution_name`
- `login`
- `institution_id`
- `institution`
- `request_id`

`accounts` is an array of `Flinks::Resources::Account`.

`links` is an array of `Flinks::Resources::Link`.

`login` is a `Flinks::Resources::Login`.

## Recommended Flow

The intended end-to-end flow is:

1. Generate an authorize token to initialize the Flinks flow.
2. Wait for the webhook callback and parse it to get the `loginId`.
3. Generate a fresh authorize token for the authorize request.
4. Authorize the session with the `loginId` and the new authorize token.
5. Use the returned `requestId` to fetch account summaries.

Example:

```ruby
first_authorize_token = Flinks::AuthorizeToken.generate

webhook = Flinks::WebhookAuthentication.from_url(
  "https://example.com/flinks/connect/callback?demo=true&loginId=181fb102-48de-44b9-de78-08de7b4f854b&institution=FlinksCapital"
)

second_authorize_token = Flinks::AuthorizeToken.generate

session = Flinks::Session.authorize(
  login_id: webhook.login_id,
  authorize_token: second_authorize_token.token
)

summary = Flinks::AccountSummary.get(request_id: session.request_id)
summary
```

Concrete example:

```ruby
Flinks::AuthorizeToken.generate

webhook = Flinks::WebhookAuthentication.from_url(
  "https://example.com/flinks/connect/callback?demo=true&loginId=181fb102-48de-44b9-de78-08de7b4f854b&institution=FlinksCapital"
)

authorize_token = Flinks::AuthorizeToken.generate

session = Flinks::Session.authorize(
  login_id: "181fb102-48de-44b9-de78-08de7b4f854b",
  authorize_token: "d19e983a-a70e-4e34-8b52-b5d321ca840f"
)

summary = Flinks::AccountSummary.get(
  request_id: "6dc74a3b-1ddf-41fb-bf95-f093f2496c92"
)
```

## Webhook Parsing

The connect callback parser extracts known query params and preserves unknown ones.

Example:

```ruby
webhook = Flinks::WebhookAuthentication.from_url(
  "https://example.com/flinks/connect/callback?demo=true&loginId=181fb102-48de-44b9-de78-08de7b4f854b&institution=FlinksCapital&requestId=req-123"
)

webhook.demo
webhook.login_id
webhook.institution
webhook.extra_query_params
```

## Development

Install dependencies:

```bash
bundle install
```

Run tests:

```bash
bundle exec rake test
```

Open a console:

```bash
bundle exec irb -I lib -r flinks
```

## Notes

- This gem currently uses `Faraday` for HTTP.
- HTTP behavior lives in `Flinks::Client`.
- Resource classes are focused on modeling and serialization.
- Some deeper nested account fields such as `Balance` and `Holder` are currently represented as hashes inside `Flinks::Resources::Account`.

## License

Released under the MIT License. See [LICENSE.txt](/Users/markmroz/Desktop/flinks/LICENSE.txt).
