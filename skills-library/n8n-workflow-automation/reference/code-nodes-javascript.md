# JavaScript Code Node Reference

Complete guide for writing JavaScript in n8n Code nodes.

---

## Mode Selection

### Run Once for All Items (95% of use cases)
- Processes entire dataset in one execution
- Access all items: `$input.all()`
- Return: Array of `{json: {...}}` objects
- **Use for**: Filtering, aggregating, transforming, multi-source merging

### Run Once for Each Item (5% of use cases)
- Runs separately for each input item
- Access current item: `$input.item`
- Return: Single `{json: {...}}` object (auto-wrapped in array)
- **Use for**: Per-item API calls, individual record processing

---

## Data Access Patterns

### Pattern 1: All Items (26% of usage — most common)
```javascript
const items = $input.all();
// Returns array: [{json: {...}}, {json: {...}}, ...]

return items.map(item => ({
  json: {
    id: item.json.id,
    name: item.json.name.toUpperCase()
  }
}));
```

### Pattern 2: First Item Only
```javascript
const first = $input.first();
// Returns single: {json: {...}}

const config = first.json;
return [{ json: { setting: config.value } }];
```

### Pattern 3: Current Item (Each Item mode)
```javascript
const current = $input.item;
// Returns single: {json: {...}}

return { json: { processed: current.json.name } };
// Note: No array wrapper needed in Each Item mode
```

### Pattern 4: Cross-Node Access
```javascript
const slackData = $node["Slack"].json;
const dbResults = $node["Postgres"].json;
const httpResponse = $node["HTTP Request"].json;
```

### Webhook Data Access (CRITICAL)
```javascript
// ❌ WRONG — data is NOT at root level
const email = $input.first().json.email;

// ✅ CORRECT — webhook data is under .body
const email = $input.first().json.body.email;
const name = $input.first().json.body.name;

// Also available:
const headers = $input.first().json.headers;
const query = $input.first().json.query;
const params = $input.first().json.params;
```

---

## Return Format

**ALWAYS return array of `{json: {...}}` objects** (Run Once for All Items mode):

```javascript
// ✅ Correct
return [{ json: { name: "Alice" } }];
return items.map(item => ({ json: { id: item.json.id } }));

// ❌ Wrong
return { name: "Alice" };           // Missing json wrapper
return [{ name: "Alice" }];         // Missing json key
return { json: { name: "Alice" } }; // Not in array
```

**Each Item mode** — return single object (no array):
```javascript
return { json: { processed: true } };
```

---

## Built-in Functions

### $helpers.httpRequest() — Complete HTTP Client
```javascript
// GET request
const data = await $helpers.httpRequest({
  method: 'GET',
  url: 'https://api.example.com/users',
  headers: { 'Authorization': 'Bearer token123' },
  qs: { page: 1, limit: 100 }  // Query parameters
});

// POST request with JSON body
const result = await $helpers.httpRequest({
  method: 'POST',
  url: 'https://api.example.com/users',
  body: { name: 'Alice', email: 'alice@example.com' },
  headers: { 'Content-Type': 'application/json' }
});

// With error handling
try {
  const data = await $helpers.httpRequest({ method: 'GET', url: '...' });
  return [{ json: data }];
} catch (error) {
  return [{ json: { error: error.message, status: 'failed' } }];
}
```

### DateTime (Luxon) — Date/Time Operations
```javascript
// Current time
const now = DateTime.now();
const utcNow = DateTime.utc();

// Parse dates
const date = DateTime.fromISO('2025-10-20T10:30:00');
const fromFormat = DateTime.fromFormat('20/10/2025', 'dd/MM/yyyy');

// Format dates
const formatted = now.toFormat('yyyy-MM-dd HH:mm:ss');
const isoString = now.toISO();
const relative = now.toRelative(); // "2 hours ago"

// Date math
const tomorrow = now.plus({ days: 1 });
const lastWeek = now.minus({ weeks: 1 });
const diff = date1.diff(date2, ['days', 'hours']);

// Timezone
const pacific = now.setZone('America/Los_Angeles');
const startOfDay = now.startOf('day');
const endOfMonth = now.endOf('month');

// Comparison
if (date1 > date2) { /* date1 is later */ }
if (now.diff(date, 'hours').hours > 24) { /* older than 24h */ }
```

### $jmespath() — JSON Querying
```javascript
const data = { people: [
  { name: "Alice", age: 30 }, { name: "Bob", age: 25 }
]};

$jmespath(data, 'people[*].name');          // ["Alice", "Bob"]
$jmespath(data, 'people[?age > `25`]');     // [{name: "Alice", age: 30}]
$jmespath(data, 'people[0].name');          // "Alice"
$jmespath(data, 'length(people)');          // 2
$jmespath(data, 'people | sort_by(@, &age)'); // Sorted by age
```

### $getWorkflowStaticData() — Persistent Storage
```javascript
// Data persists across executions (resets on deploy)
const store = $getWorkflowStaticData('global');

// Read
const lastRun = store.lastRun || 'never';
const counter = store.counter || 0;

// Write
store.lastRun = new Date().toISOString();
store.counter = counter + 1;

// Use for: deduplication, last-sync timestamps, counters, caching
```

---

## Common Patterns

### 1. Multi-Source Aggregation
```javascript
const source1 = $node["API 1"].json;
const source2 = $node["API 2"].json;

return [{
  json: {
    combined: [...(source1.items || []), ...(source2.items || [])],
    totalCount: (source1.count || 0) + (source2.count || 0)
  }
}];
```

### 2. Filter and Transform
```javascript
const items = $input.all();
return items
  .filter(item => item.json.status === 'active' && item.json.amount > 100)
  .map(item => ({
    json: {
      id: item.json.id,
      name: item.json.name.trim().toUpperCase(),
      amount: parseFloat(item.json.amount)
    }
  }));
```

### 3. Group By / Aggregate
```javascript
const items = $input.all();
const grouped = {};

for (const item of items) {
  const key = item.json.category;
  if (!grouped[key]) grouped[key] = { category: key, count: 0, total: 0 };
  grouped[key].count++;
  grouped[key].total += item.json.amount;
}

return Object.values(grouped).map(g => ({ json: g }));
```

### 4. Deduplication
```javascript
const items = $input.all();
const seen = new Set();

return items.filter(item => {
  const key = item.json.email.toLowerCase();
  if (seen.has(key)) return false;
  seen.add(key);
  return true;
});
```

### 5. JSON Comparison (Diff Detection)
```javascript
const oldData = $node["DB Query"].json;
const newData = $node["API Call"].json;

const changes = [];
for (const [key, value] of Object.entries(newData)) {
  if (JSON.stringify(oldData[key]) !== JSON.stringify(value)) {
    changes.push({ field: key, old: oldData[key], new: value });
  }
}

return [{ json: { hasChanges: changes.length > 0, changes } }];
```

### 6. Safe Null Handling
```javascript
const items = $input.all();
return items.map(item => ({
  json: {
    name: item.json.name ?? 'Unknown',
    email: item.json.email?.toLowerCase() ?? '',
    tags: Array.isArray(item.json.tags) ? item.json.tags : [],
    amount: Number(item.json.amount) || 0
  }
}));
```

---

## Top 5 Errors and Fixes

### 1. Empty Code Node
**Error**: "Code doesn't return items properly" or no output
**Fix**: Always return an array of `{json: {...}}` objects

### 2. Using Expression Syntax in Code Nodes
```javascript
// ❌ WRONG — {{ }} is for expression fields, not Code nodes
const name = {{ $json.name }};

// ✅ CORRECT
const name = $input.first().json.name;
```

### 3. Incorrect Return Wrapper
```javascript
// ❌ Returns object, not array
return { json: { result: "done" } };

// ✅ Returns array
return [{ json: { result: "done" } }];
```

### 4. Missing Null Checks
```javascript
// ❌ Crashes if user or address is undefined
const city = item.json.user.address.city;

// ✅ Safe access
const city = item.json.user?.address?.city ?? 'Unknown';
```

### 5. Webhook Body Nesting
```javascript
// ❌ Looks at root (headers, body, query, params)
const email = $input.first().json.email;

// ✅ Data is under .body
const email = $input.first().json.body.email;
```

---

## What's NOT Available

- `axios`, `node-fetch`, `request` → Use `$helpers.httpRequest()`
- `lodash`, `underscore` → Use native JS (map, filter, reduce, Set, etc.)
- `moment`, `dayjs` → Use built-in `DateTime` (Luxon)
- `require()`, `import` → No npm packages
- `fs`, `path`, `child_process` → No filesystem/OS access
- `Buffer` for complex operations → Use built-in `btoa()`/`atob()` or `$helpers`
