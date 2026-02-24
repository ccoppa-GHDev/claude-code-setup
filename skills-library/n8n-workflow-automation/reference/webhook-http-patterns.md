# Webhook & HTTP API Patterns Reference

Comprehensive guide for webhook processing and REST API integration in n8n.

---

## Part 1: Webhook Processing

### Pattern
```
Webhook → Validate → Transform → Action → Response
```

### Webhook Node Configuration
```javascript
{
  path: "my-endpoint",          // URL: https://n8n.example.com/webhook/my-endpoint
  httpMethod: "POST",           // GET, POST, PUT, DELETE
  responseMode: "onReceived",   // or "lastNode" for custom response
  responseData: "allEntries"    // or "firstEntryJson"
}
```

### Data Structure (CRITICAL)
```json
{
  "headers": { "content-type": "application/json", "x-api-key": "..." },
  "params": { "id": "123" },        // URL: /webhook/path/:id
  "query": { "token": "abc" },      // URL: /webhook/path?token=abc
  "body": {                          // ⚠️ YOUR DATA IS HERE
    "name": "John",
    "email": "john@example.com"
  }
}
```

**Access patterns**:
```javascript
{{ $json.body.email }}                  // Body field (most common)
{{ $json.body.user.name }}              // Nested object
{{ $json.body.items[0].price }}         // Array element
{{ $json.headers['x-api-key'] }}        // Header
{{ $json.query.page }}                  // Query parameter
{{ $json.params.id }}                   // URL parameter
```

### Response Modes

**onReceived** (default) — Instant 200 OK, workflow runs in background:
- Use for: Long-running workflows, fire-and-forget
- Caller gets immediate response

**lastNode** — Wait for workflow, send custom response:
- Use for: Synchronous processing, form submissions, API endpoints
- Requires Webhook Response node at end

**Webhook Response Node**:
```javascript
{
  statusCode: 200,
  headers: { "Content-Type": "application/json" },
  body: { status: "success", id: "={{ $json.record_id }}" }
}
```

### Authentication

**Query token** (simple):
```javascript
// IF node: {{ $json.query.token }} equals "your-secret"
```

**Header auth** (better):
```javascript
// IF node: {{ $json.headers['x-api-key'] }} equals "your-key"
```

**Signature verification** (best — for Stripe, GitHub, etc.):
```javascript
// Code node
const crypto = require('crypto');
const signature = $input.item.headers['x-signature'];
const secret = $credentials.webhookSecret;
const calculated = crypto.createHmac('sha256', secret)
  .update(JSON.stringify($input.item.body)).digest('hex');
if (signature !== `sha256=${calculated}`) throw new Error('Invalid signature');
return $input.item.body;
```

### Common Use Cases

**Form submission**: Webhook → IF (validate) → Postgres (insert) → Email (confirm) → Webhook Response
**Payment webhook**: Webhook → Code (verify signature) → DB (update order) → Slack (notify)
**Chat command**: Webhook → Code (parse) → HTTP Request (fetch data) → Webhook Response
**GitHub webhook**: Webhook → IF (action="opened") → Set (extract PR info) → Slack (notify)

---

## Part 2: HTTP API Integration

### Pattern
```
Trigger → HTTP Request → Transform → Action → Error Handler
```

### Authentication Methods

**Bearer token** (most common):
```javascript
{
  authentication: "predefinedCredentialType",
  nodeCredentialType: "httpHeaderAuth"
}
```

**API Key (header)**:
```javascript
{ sendHeaders: true, headerParameters: { "X-API-Key": "={{ $credentials.apiKey }}" } }
```

**API Key (query)**:
```javascript
{ sendQuery: true, queryParameters: { "api_key": "={{ $credentials.apiKey }}" } }
```

**Basic Auth**: `nodeCredentialType: "httpBasicAuth"`
**OAuth2**: `nodeCredentialType: "oAuth2Api"`

**Rule**: NEVER hardcode credentials in parameters. Always use the n8n credentials system.

### Pagination Patterns

**Offset-based**:
```
Set (page=1) → HTTP Request (GET ?page={{ $json.page }}) → Code (check has_more)
  → IF (has_more) → Set (page+1) → Loop back to HTTP Request
```

**Cursor-based**:
```
HTTP Request (GET) → Code (extract next_cursor)
  → IF (cursor exists) → Set (cursor={{ $json.next_cursor }}) → Loop
```

**Code for pagination check**:
```javascript
const response = $input.first().json;
return [{ json: {
  items: response.results,
  page: ($json.page || 1) + 1,
  has_more: response.next !== null
}}];
```

### Rate Limiting

**Wait between requests**:
```
Split In Batches (1 per batch) → HTTP Request → Wait (1 second) → Loop
```

**Exponential backoff**:
```javascript
const retryCount = $json.retryCount || 0;
const delay = Math.pow(2, retryCount) * 1000; // 1s, 2s, 4s
return [{ json: { retryCount: retryCount + 1, waitTime: delay } }];
```

**Respect rate limit headers**:
```javascript
const remaining = parseInt($input.first().json.headers['x-ratelimit-remaining'] || '999');
const resetTime = parseInt($input.first().json.headers['x-ratelimit-reset'] || '0');
if (remaining < 10) {
  return [{ json: { shouldWait: true, waitSeconds: Math.max(resetTime - Math.floor(Date.now()/1000), 0) } }];
}
return [{ json: { shouldWait: false } }];
```

### Error Handling

**Pattern 1: Retry on failure**:
```
HTTP Request (continueOnFail: true) → IF (error) → Wait (5s) → HTTP Request (retry)
```

**Pattern 2: Fallback API**:
```
HTTP Request (Primary, continueOnFail: true) → IF (failed) → HTTP Request (Fallback)
```

**Pattern 3: Error Trigger workflow**:
```
Error Trigger → Set (extract error) → Slack (alert) → Database (log error)
```

**Pattern 4: Circuit breaker**:
```javascript
const failures = $json.recentFailures || 0;
if (failures >= 5) throw new Error('Circuit breaker open');
return [{ json: { canProceed: true } }];
```

**IF condition for error check**:
```javascript
{{ $json.error }} is empty    // Success path
{{ $json.statusCode }} < 400  // HTTP status check
```

### Response Transformation

**Extract nested data**:
```javascript
const response = $input.first().json;
return response.data.items.map(item => ({
  json: { id: item.id, name: item.attributes.name, email: item.attributes.contact.email }
}));
```

**Flatten arrays**:
```javascript
return $input.all().flatMap(item =>
  item.json.results.map(result => ({ json: { parent_id: item.json.id, ...result } }))
);
```

### Common Use Cases

**Data fetch & store**: Schedule → HTTP Request (GET API) → Code (transform) → Postgres (upsert)
**API to API**: Schedule → HTTP Request (GET Jira) → Set (format) → HTTP Request (POST Slack)
**Data enrichment**: DB (read contacts) → HTTP Request (enrichment API) → DB (update)
**Health monitoring**: Schedule (5min) → HTTP Request (GET /health) → IF (unhealthy) → Slack + PagerDuty

---

## Cross-Cutting Best Practices

### Security
- [ ] Use HTTPS only
- [ ] Store secrets in credentials (never hardcode)
- [ ] Validate incoming data (webhooks)
- [ ] Use environment variables for URLs: `{{ $env.API_BASE_URL }}/users`

### Error Handling
- [ ] `continueOnFail: true` on HTTP Request nodes
- [ ] IF node to check for errors after API calls
- [ ] Error Trigger workflow for alerts
- [ ] Retry logic for flaky external services

### Performance
- [ ] Batch processing for large datasets (Split In Batches)
- [ ] Rate limiting for external APIs
- [ ] Caching for repeated requests (IF check → Cache or Fetch)
- [ ] Conditional fetching (If-Modified-Since header)

### Testing
- [ ] Test APIs with curl/Postman first
- [ ] Use Manual Trigger for development
- [ ] Test error scenarios (timeout, 500, empty response)
- [ ] Verify response structure before building transforms
