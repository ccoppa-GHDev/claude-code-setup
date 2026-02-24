# Database Operations & Scheduled Tasks Reference

Patterns for database workflows and recurring automation.

---

## Part 1: Database Operations

### Pattern
```
Trigger → Query/Read → Transform → Write/Update → Verify/Log
```

### Supported Databases
Postgres, MySQL, MongoDB, Microsoft SQL, SQLite, Redis, and more via community nodes.

### CRITICAL: Parameterized Queries

**Always use parameterized queries** to prevent SQL injection:

```javascript
// ❌ NEVER — SQL injection vulnerability
{ query: `SELECT * FROM users WHERE email = '${$json.email}'` }

// ✅ ALWAYS — Parameterized
{
  operation: "executeQuery",
  query: "SELECT * FROM users WHERE email = $1 AND status = $2 LIMIT $3",
  parameters: ["={{ $json.body.email }}", "active", "100"]
}
```

### Common Database Operations

**Select with parameters**:
```javascript
{
  operation: "executeQuery",
  query: "SELECT id, name, email FROM users WHERE created_at > $1 ORDER BY created_at DESC LIMIT $2",
  parameters: ["={{ $json.since }}", "1000"]
}
```

**Insert**:
```javascript
{
  operation: "insert",
  table: "contacts",
  columns: "name, email, source, created_at",
  returnFields: "id"
}
```

**Upsert** (insert or update):
```javascript
{
  operation: "upsert",
  table: "users",
  columns: "email, name, updated_at",
  conflictColumns: "email"  // Match on email
}
```

**Update**:
```javascript
{
  operation: "update",
  table: "users",
  updateKey: "id",
  columns: "name, email, updated_at"
}
```

### Data Synchronization Pattern

**Incremental sync** (most efficient):
```
1. Schedule (every 15 minutes)
2. Postgres (SELECT * FROM users WHERE updated_at > $1 LIMIT 1000)
   params: [last_sync_timestamp]
3. IF (records exist)
4. Set (map source schema → target schema)
5. MySQL (UPSERT users)
6. Postgres (UPDATE sync_log SET last_sync = NOW())
7. Slack (notify: "Synced X records")
```

**Full sync** (when incremental isn't possible):
```
1. Schedule (daily at 2 AM)
2. Source DB (SELECT all)
3. Target DB (TRUNCATE + INSERT or UPSERT)
4. Log (record sync completion)
```

### Batch Processing for Large Datasets

```
1. Postgres (SELECT count(*) FROM large_table WHERE needs_processing = true)
2. Code (calculate batch count: Math.ceil(count / 1000))
3. Split In Batches (1000 items per batch)
4. Postgres (SELECT * FROM large_table WHERE needs_processing = true LIMIT 1000 OFFSET {{ $json.offset }})
5. Code (process batch)
6. Postgres (UPDATE large_table SET processed = true WHERE id IN (...))
7. Loop (back to step 4 until done)
```

### ETL (Extract, Transform, Load)

```
1. Schedule (daily at 2 AM)
2. [Parallel branches]
   ├─ Postgres (sales data)
   ├─ MySQL (customer data)
   └─ HTTP Request (marketing data)
3. Merge (combine all sources)
4. Code (transform and clean)
5. Data Warehouse (load)
6. Slack (notify completion)
```

### Database Security Best Practices

- **Parameterized queries** always (SQL injection prevention)
- **Read-only users** for AI agent tools and query-only workflows
- **Connection pooling** via n8n credentials
- **LIMIT clauses** on all SELECT queries (prevent memory issues)
- **Schema restrictions**: Grant only needed table access

```sql
-- Read-only user for AI tools
CREATE USER ai_readonly WITH PASSWORD 'secure_password';
GRANT SELECT ON customers, orders, products TO ai_readonly;
-- NO INSERT, UPDATE, DELETE
```

### Common Database Gotchas

1. **Missing LIMIT**: `SELECT * FROM users` can return millions of rows
2. **String interpolation in SQL**: Always parameterize
3. **Timezone mismatches**: Ensure DB timezone matches workflow timezone
4. **NULL handling**: Use COALESCE in queries for default values
5. **Transaction isolation**: Multi-step operations need explicit transactions

---

## Part 2: Scheduled Tasks

### Pattern
```
Schedule Trigger → Fetch Data → Process → Deliver → Log/Notify
```

### Schedule Trigger Configuration

**Cron expression** (most precise):
```javascript
{
  rule: {
    interval: [{
      field: "cronExpression",
      expression: "0 9 * * 1-5"    // 9 AM, Mon-Fri
    }]
  },
  timezone: "America/Los_Angeles"    // ← ALWAYS SPECIFY!
}
```

Common cron patterns:
| Expression | Meaning |
|-----------|---------|
| `0 9 * * *` | Daily at 9 AM |
| `0 9 * * 1-5` | Weekdays at 9 AM |
| `0 */2 * * *` | Every 2 hours |
| `*/15 * * * *` | Every 15 minutes |
| `0 0 1 * *` | 1st of month at midnight |
| `0 9 * * 1` | Mondays at 9 AM |

**Interval mode** (simpler):
```javascript
{
  rule: {
    interval: [{
      field: "minutes",
      minutesInterval: 15            // Every 15 minutes
    }]
  }
}
```

**Days & Hours mode**:
```javascript
{
  rule: {
    interval: [{
      field: "hours",
      betweenStart: 9,               // Start at 9 AM
      betweenEnd: 17                  // End at 5 PM
    }]
  },
  timezone: "America/Los_Angeles"
}
```

### CRITICAL: Always Set Timezone

```javascript
// ❌ Uses server timezone (unpredictable, DST issues)
{ rule: { interval: [{ field: "cronExpression", expression: "0 9 * * *" }] } }

// ✅ Explicit timezone
{
  rule: { interval: [{ field: "cronExpression", expression: "0 9 * * *" }] },
  timezone: "America/Los_Angeles"
}
```

Without explicit timezone:
- Server timezone may differ from expected
- DST transitions cause off-by-one-hour issues
- Cloud deployments may use UTC

### Preventing Overlapping Executions

If a scheduled workflow runs longer than its interval:

**Option 1: Execution lock using static data**:
```javascript
// Code node at start
const store = $getWorkflowStaticData('global');
if (store.isRunning) {
  return [{ json: { skipped: true, reason: "Previous execution still running" } }];
}
store.isRunning = true;

// Code node at end (or in Error Trigger)
const store = $getWorkflowStaticData('global');
store.isRunning = false;
```

**Option 2: n8n workflow settings**:
- Set execution timeout
- Configure "On Error" behavior
- Use execution queuing

### Common Scheduled Task Patterns

**Daily report**:
```
1. Schedule (daily 9 AM, timezone explicit)
2. HTTP Request (fetch analytics API)
3. Code (aggregate: totals, averages, trends)
4. Set (format report data)
5. Email (send formatted report)
6. Error Trigger → Slack (#ops-alerts)
```

**Data cleanup**:
```
1. Schedule (weekly, Sunday 2 AM)
2. Postgres (DELETE FROM logs WHERE created_at < NOW() - INTERVAL '90 days')
3. Postgres (VACUUM ANALYZE logs)
4. Slack (notify: "Cleaned X records")
```

**Health monitoring**:
```
1. Schedule (every 5 minutes)
2. HTTP Request (GET /health, continueOnFail: true)
3. IF (status !== 200 OR response time > 2000ms)
4. Slack (alert #ops-team)
5. PagerDuty (create incident)
```

**Data sync**:
```
1. Schedule (every 15 minutes)
2. Source DB (query new/updated records since last sync)
3. IF (records exist)
4. Transform (map schema)
5. Target DB (upsert)
6. Update sync checkpoint
```

### Error Handling for Scheduled Tasks

**Error Trigger Workflow** (recommended for all scheduled tasks):
```
Error Trigger → Set (extract error details) → Slack (alert) → Database (log error)
```

Error details available:
```javascript
{{ $json.execution.id }}           // Execution ID
{{ $json.execution.error.message }}  // Error message
{{ $json.workflow.name }}            // Workflow name
{{ $json.execution.startedAt }}     // Start time
```

### Monitoring Best Practices

- **Log execution results**: Record success/failure, item counts, duration
- **Set up alerts**: Error Trigger → immediate notification
- **Track timing**: Log execution duration, flag slowdowns
- **Dashboard**: Aggregate logs for workflow health overview
- **Timeout settings**: Set appropriate timeouts for each workflow
