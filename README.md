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

### Authorize Cached Session

This calls `/Authorize` with:

```json
{
  "LoginId": "...",
  "MostRecentCached": true
}
```

Usage:

```ruby
session = Flinks.client.authorize_cached_session(login_id: "login-id")
session.class
session.attributes
```

Successful responses return `Flinks::Resources::Session`.

### Get Accounts Summary

This calls `/GetAccountsSummary` with the configured `x-api-key`.

Usage:

```ruby
summary = Flinks.client.get_accounts_summary(request_id: "request-id")
summary.class
summary.attributes
```

Optional flags:

```ruby
summary = Flinks.client.get_accounts_summary(
  request_id: "request-id",
  with_balance: true,
  with_account_identity: true
)
```

Successful responses return `Flinks::Resources::AccountSummary`.

## Resource Models

All API models inherit from `Flinks::Resources::Resource` and use:

- `ActiveModel::Model`
- `ActiveModel::Attributes`
- `ActiveModel::Serializers::JSON`

Current resources:

- `Flinks::Resources::AuthorizeToken`
- `Flinks::Resources::ErrorObject`
- `Flinks::Resources::Session`
- `Flinks::Resources::AccountSummary`
- `Flinks::Resources::Account`
- `Flinks::Resources::Link`
- `Flinks::Resources::Login`
- `Flinks::Resources::Webhook::Authentication`

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

## Webhook Parsing

The connect callback parser extracts known query params and preserves unknown ones.

Example:

```ruby
auth = Flinks::Resources::Webhook::Authentication.from_url(
  "https://example.com/flinks/connect/callback?demo=true&loginId=181fb102-48de-44b9-de78-08de7b4f854b&institution=FlinksCapital&requestId=req-123"
)

auth.demo
auth.login_id
auth.institution
auth.extra_query_params
```

## Example IRB Session

```ruby
response = Flinks::Resources::AuthorizeToken.generate
response

session = Flinks.client.authorize_cached_session(login_id: "your-login-id")
session

summary = Flinks.client.get_accounts_summary(request_id: session.request_id)
summary
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
