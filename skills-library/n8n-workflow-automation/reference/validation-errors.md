# n8n Validation Reference

Error catalog, false positives, validation profiles, and recovery strategies.

---

## The Validation Loop

**Validation is iterative** — expect 2-3 cycles, not one-shot success.

```
Configure → validate_node (23s thinking) → Read errors → Fix → validate_node (58s fixing) → Repeat
```

From telemetry: 7,841 validate → fix cycles observed. 79% of validations lead to feedback loops.

---

## Error Types by Frequency

### Errors (Must Fix — Block Execution)

**1. missing_required (45% of errors)**
Required field not provided.

```json
{ "type": "missing_required", "property": "channel",
  "message": "Channel name is required", "fix": "Provide channel name" }
```

**How to fix**: Use `get_node` to see required fields. Add the missing field.

Common examples:
- Slack: missing `channel` or `text` for message/post
- HTTP Request: missing `url`
- Postgres: missing `query` for executeQuery
- Conditional fields: `body` required when `sendBody: true`

**2. invalid_value (28%)**
Value doesn't match allowed options.

```json
{ "type": "invalid_value", "property": "operation",
  "message": "Must be one of: post, update, delete", "current": "send" }
```

**How to fix**: Check allowed values in error message or `get_node`. Case-sensitive!

**3. type_mismatch (12%)**
Wrong data type.

```json
{ "type": "type_mismatch", "property": "limit",
  "message": "Expected number, got string", "current": "100" }
```

**How to fix**: Use correct type. `100` not `"100"`, `true` not `"true"`.

Common: limit (number not string), sendHeaders (boolean not string), tags (array not object).

**4. invalid_expression (8%)**
Expression syntax error.

```json
{ "type": "invalid_expression", "property": "text",
  "message": "Invalid expression: $json.name", "current": "$json.name" }
```

**How to fix**: Add `={{ }}` wrapper. Check node references. Use safe navigation (`?.`).

Common causes:
- Missing `={{ }}` around expression
- Typo in node name: `$node['HTTP Requets']` → `$node['HTTP Request']`
- Missing `.body` for webhook data
- Undefined nested access → use `$json.data?.user?.name`

**5. invalid_reference (5%)**
Referenced node doesn't exist.

```json
{ "type": "invalid_reference", "message": "Node 'Transform Data' does not exist" }
```

**How to fix**: Fix node name spelling. Use `cleanStaleConnections` operation. Check if node was renamed or deleted.

### Warnings (Should Fix — Don't Block)

**6. best_practice** — Missing error handling, retry logic, input validation

**7. deprecated** — Old typeVersion or API

**8. performance** — Unbounded queries, large datasets without pagination

### Auto-Fixed

**9. operator_structure (2%)** — ✅ Fixed automatically on every workflow save
- Binary operators: removes incorrect `singleValue`
- Unary operators: adds `singleValue: true`
- IF/Switch: adds `conditions.options` metadata

**Don't manually fix these!**

---

## Validation Profiles

| Profile | Use When | Trade-off |
|---------|----------|-----------|
| `minimal` | Quick editing checks | Fast but misses issues |
| `runtime` | **Pre-deployment (RECOMMENDED)** | Balanced — catches real errors |
| `ai-friendly` | AI-generated configs | 60% fewer false positives |
| `strict` | Production/critical workflows | Maximum safety, many warnings |

### Strategy: Progressive Strictness
```
Development  → ai-friendly (fewer distractions)
Pre-deploy   → runtime (balanced)
Production   → strict (maximum safety, review each warning)
```

---

## False Positives

~40% of warnings are acceptable in specific contexts. Use `ai-friendly` profile to reduce by 60%.

### When Warnings Are Acceptable

| Warning | Acceptable When | Fix When |
|---------|----------------|----------|
| Missing error handling | Dev/testing, non-critical notifications, manual triggers | Production automation, critical data |
| No retry logic | APIs with built-in retry, idempotent ops, local services | Flaky external APIs, non-idempotent POSTs |
| Missing rate limiting | Internal APIs, low-volume workflows | Public APIs, high-volume loops |
| Unbounded query | Small known datasets, aggregation queries | Large production tables |
| Missing input validation | Internal webhooks, trusted sources (Stripe signed) | Public-facing webhooks |
| Hardcoded credentials | Public APIs (no auth), demo workflows | **ALWAYS fix for real credentials** |

### Known n8n Issues (Always Acceptable)
- **#304**: IF node metadata warning — auto-sanitization adds on save
- **#306**: Switch branch count mismatch — expected when using fallback
- **#338**: Credential validation in test mode — validated at runtime, not build time

### Decision Framework
```
Security warning?          → Always fix
Production workflow?       → Continue checking
Handles critical data?     → Fix the warning
Known workaround exists?   → Acceptable if documented
```

**Golden Rule**: If you accept a warning, document WHY.

---

## Recovery Strategies

### Strategy 1: Start Fresh
When configuration is severely broken:
1. Get required fields from `get_node`
2. Create minimal valid config
3. Add features one by one
4. Validate after each addition

### Strategy 2: Progressive Validation
When too many errors at once:
```javascript
// Step 1: Minimal config
config = { resource: "message", operation: "post", channel: "#general", text: "Hello" };
validate_node(config); // ✅ Valid

// Step 2: Add features one by one
config.blocks = [...];
validate_node(config); // Check

config.attachments = [...];
validate_node(config); // Check
```

### Strategy 3: Clean Stale Connections
When "node not found" errors:
```
n8n_update_partial_workflow({
  id: "workflow-id",
  operations: [{ type: "cleanStaleConnections" }]
})
```

### Strategy 4: Auto-fix Preview
For operator structure issues:
```
// Preview first
n8n_autofix_workflow({ id: "...", applyFixes: false })

// Apply if looks good
n8n_autofix_workflow({ id: "...", applyFixes: true })
```

### Strategy 5: Binary Search
When workflow validates but executes incorrectly:
1. Remove half the nodes
2. Validate and test
3. Problem in removed half or remaining half?
4. Repeat until isolated

---

## Validation Result Structure

```javascript
{
  valid: false,
  errors: [
    { type: "missing_required", property: "channel", message: "...", fix: "..." }
  ],
  warnings: [
    { type: "best_practice", property: "errorHandling", message: "...", suggestion: "..." }
  ],
  suggestions: [
    { type: "optimization", message: "..." }
  ],
  summary: { hasErrors: true, errorCount: 1, warningCount: 1, suggestionCount: 1 }
}
```

**Reading order**:
1. Check `valid` — if true, you're done
2. Fix `errors` first (must fix)
3. Review `warnings` (context-dependent)
4. Consider `suggestions` (optional improvements)

---

## Best Practices

**Do**:
- Validate after every significant change
- Read error messages completely (they contain fix guidance)
- Fix iteratively (one error at a time)
- Use `runtime` profile for pre-deployment
- Trust auto-sanitization for operator issues
- Use `get_node` when unclear about requirements
- Document accepted false positives

**Don't**:
- Skip validation before activation
- Try to fix all errors at once
- Use `strict` during development (too noisy)
- Manually fix operator structure issues (auto-fixed)
- Deploy with unresolved errors
- Ignore ALL warnings (some matter)
