# n8n Expression Syntax Reference

Guide for writing expressions in n8n node fields (Set node, IF conditions, field values, etc.).

---

## Expression Format

All expressions use the `={{ }}` format:
```
={{ $json.fieldName }}
```

The `=` prefix tells n8n this is an expression, not literal text.

---

## Core Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `$json` | Current item's data | `{{ $json.email }}` |
| `$json.body` | **Webhook payload** (CRITICAL!) | `{{ $json.body.email }}` |
| `$node["Name"]` | Another node's output | `{{ $node["HTTP Request"].json.status }}` |
| `$now` | Current timestamp (Luxon DateTime) | `{{ $now.toFormat('yyyy-MM-dd') }}` |
| `$today` | Start of today | `{{ $today }}` |
| `$env` | Environment variables | `{{ $env.API_KEY }}` |
| `$input.item` | Current input item | `{{ $input.item.json.name }}` |
| `$input.all()` | All input items | `{{ $input.all()[0].json.name }}` |
| `$execution.id` | Current execution ID | `{{ $execution.id }}` |
| `$workflow.id` | Current workflow ID | `{{ $workflow.id }}` |
| `$workflow.name` | Workflow name | `{{ $workflow.name }}` |
| `$runIndex` | Current run index in loop | `{{ $runIndex }}` |
| `$itemIndex` | Current item index | `{{ $itemIndex }}` |

---

## Webhook Data Structure

**#1 rule**: Webhook data is nested under `.body`:

```javascript
// The webhook node produces this structure:
{
  "headers": { "content-type": "application/json", ... },
  "params": { "id": "123" },           // URL params: /webhook/:id
  "query": { "token": "abc" },         // Query string: ?token=abc
  "body": {                            // ⚠️ YOUR DATA IS HERE
    "name": "John",
    "email": "john@example.com"
  }
}
```

**Accessing webhook data**:
```javascript
{{ $json.body.email }}              // POST body field
{{ $json.body.user.name }}          // Nested object
{{ $json.body.items[0].price }}     // Array element
{{ $json.headers['content-type'] }} // Request header
{{ $json.query.page }}              // Query parameter
{{ $json.params.id }}               // URL parameter
```

---

## 15 Common Mistakes and Fixes

### 1. Missing Double Braces
```javascript
❌  $json.name              // Literal text, not expression
✅  {{ $json.name }}         // Expression evaluated
```

### 2. Forgetting .body for Webhooks
```javascript
❌  {{ $json.email }}        // Empty — email is inside body
✅  {{ $json.body.email }}   // Correct webhook data access
```

### 3. Spaces in Field Names
```javascript
❌  {{ $json.First Name }}   // Syntax error
✅  {{ $json["First Name"] }} // Bracket notation required
```

### 4. Spaces in Node Names
```javascript
❌  {{ $node.HTTP Request.json.data }}        // Syntax error
✅  {{ $node["HTTP Request"].json.data }}     // Bracket notation
```

### 5. Case Sensitivity
```javascript
❌  {{ $json.Email }}        // Wrong case
✅  {{ $json.email }}        // Match exact field name
```

### 6. Double-Wrapping Expressions
```javascript
❌  {{ {{ $json.name }} }}   // Nested braces
✅  {{ $json.name }}         // Single wrap
```

### 7. Array Access Without Index
```javascript
❌  {{ $json.items.name }}    // items is array, not object
✅  {{ $json.items[0].name }} // Access specific element
```

### 8. Using Expressions in Code Nodes
```javascript
❌  // Inside Code node:
    const name = {{ $json.name }};

✅  // Inside Code node:
    const name = $input.first().json.name;
```

### 9. Missing Quotes in String Concatenation
```javascript
❌  {{ "Hello " + $json.name + " welcome" }}  // May fail
✅  {{ `Hello ${$json.name} welcome` }}        // Template literal
```

### 10. Wrong Path After $node
```javascript
❌  {{ $node["Set"].name }}      // Missing .json
✅  {{ $node["Set"].json.name }} // Need .json between node and field
```

### 11. Using = Prefix Outside JSON Fields
In n8n UI expression fields, the `=` prefix switches to expression mode. Don't use it in JSON or raw text contexts.

### 12. Dynamic Webhook Paths
```javascript
❌  path: "={{ $json.path }}"  // Expressions don't work in webhook path
✅  path: "my-static-path"     // Must be static string
```

### 13. Missing .json in $node Reference
```javascript
❌  {{ $node["Slack"].channel }}      // No .json
✅  {{ $node["Slack"].json.channel }} // Correct path
```

### 14. Empty Bracket Notation
```javascript
❌  {{ $json[] }}              // Empty brackets
✅  {{ $json["fieldName"] }}   // Specify field name
```

### 15. Expressions in Credential Fields
```javascript
❌  API Key: {{ $env.API_KEY }}  // Expressions don't work in credentials
✅  Use the n8n credentials system directly
```

---

## Practical Expression Examples

### String Operations
```javascript
{{ $json.name.toUpperCase() }}
{{ $json.name.trim() }}
{{ $json.email.split('@')[1] }}            // Domain from email
{{ $json.text.substring(0, 100) }}          // First 100 chars
{{ $json.name.replace(/\s+/g, '-') }}       // Spaces to dashes
{{ `Hello ${$json.first} ${$json.last}` }}  // Template literal
```

### Number Operations
```javascript
{{ Math.round($json.price * 100) / 100 }}  // Round to 2 decimals
{{ parseInt($json.quantity) }}              // String to integer
{{ parseFloat($json.amount) }}             // String to float
{{ ($json.price * $json.quantity).toFixed(2) }} // Calculate total
```

### Date Operations
```javascript
{{ $now.toFormat('yyyy-MM-dd') }}           // Today: 2025-10-20
{{ $now.toFormat('HH:mm:ss') }}             // Current time
{{ $now.minus({days: 7}).toISO() }}         // 7 days ago
{{ DateTime.fromISO($json.date).toFormat('MMM dd, yyyy') }}
{{ $now.diff(DateTime.fromISO($json.created), 'days').days }}
```

### Conditional (Ternary)
```javascript
{{ $json.status === 'active' ? 'Yes' : 'No' }}
{{ $json.score >= 80 ? 'Pass' : 'Fail' }}
{{ $json.name || 'Anonymous' }}             // Fallback for empty
{{ $json.data?.nested?.value ?? 'Default' }} // Safe navigation + nullish coalescing
```

### Array Operations
```javascript
{{ $json.tags.join(', ') }}                 // Array to string
{{ $json.items.length }}                    // Count items
{{ $json.items.map(i => i.name).join(', ') }} // Extract field
{{ $json.items.filter(i => i.active).length }} // Count active
```

### Boolean Checks (for IF nodes)
```javascript
{{ $json.body.email }}        is not empty   // Check field exists
{{ $json.status }}            equals "active"
{{ $json.amount }}            greater than 100
{{ $json.tags }}              contains "urgent"
```

---

## Where NOT to Use Expressions

| Context | Why | What to Use Instead |
|---------|-----|-------------------|
| Code nodes | Code is already JavaScript/Python | Direct variable access |
| Webhook URL paths | Must be static | Static string |
| Credential fields | Security restriction | n8n credentials system |
| Node names | Must be static | Static string |

---

## Expression vs Code Node Decision

| Scenario | Use Expression | Use Code Node |
|----------|---------------|---------------|
| Access single field | ✅ `{{ $json.name }}` | Overkill |
| Simple transform | ✅ `{{ $json.name.toUpperCase() }}` | Overkill |
| Conditional value | ✅ `{{ $json.x ? 'a' : 'b' }}` | Overkill |
| Date formatting | ✅ `{{ $now.toFormat('...') }}` | Overkill |
| Filter array of items | ❌ | ✅ Use Code node |
| Multi-step logic | ❌ | ✅ Use Code node |
| HTTP requests | ❌ | ✅ `$helpers.httpRequest()` |
| Error handling | ❌ | ✅ try/catch in Code |
| Complex data merging | ❌ | ✅ Use Code node |
