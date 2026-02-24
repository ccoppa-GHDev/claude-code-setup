# AI Agent Workflow Patterns Reference

Building AI agents with tools, memory, and reasoning in n8n.

---

## Pattern
```
Trigger → AI Agent (Model + Tools + Memory) → [Process] → Output
```

---

## 8 AI Connection Types

| Type | Purpose | Example Node |
|------|---------|-------------|
| `ai_languageModel` | The LLM brain | OpenAI Chat Model, Anthropic |
| `ai_tool` | Functions agent can call | HTTP Request, Postgres, Code, any node |
| `ai_memory` | Conversation context | Window Buffer Memory |
| `ai_outputParser` | Parse structured output | JSON Output Parser |
| `ai_embedding` | Vector embeddings | OpenAI Embeddings |
| `ai_vectorStore` | Vector database | Pinecone, Qdrant |
| `ai_document` | Document loaders | File loaders |
| `ai_textSplitter` | Text chunking | Recursive Text Splitter |

**Connection syntax in workflows**:
```javascript
// In n8n_update_partial_workflow:
{
  type: "addConnections",
  connections: [{
    source: "OpenAI Chat Model",
    target: "AI Agent",
    connectionType: "ai_languageModel"  // ← Specify AI connection type
  }]
}
```

---

## AI Agent Node Configuration

```javascript
{
  agent: "conversationalAgent",     // or "openAIFunctionsAgent"
  promptType: "define",
  text: "You are a helpful assistant that can search docs and query databases."
}
```

**Connections to AI Agent**:
```
OpenAI Chat Model ──[ai_languageModel]──→ AI Agent
HTTP Request Tool  ──[ai_tool]──────────→ AI Agent
Postgres Tool      ──[ai_tool]──────────→ AI Agent
Window Buffer Mem  ──[ai_memory]────────→ AI Agent
```

---

## ANY Node Can Be a Tool

**Critical concept**: Connect ANY n8n node to the AI Agent via the `ai_tool` port.

### Requirements
1. Connect node to AI Agent via `ai_tool` port (NOT main port!)
2. Configure tool `name` and `description`
3. Define input schema (optional)

### Example: HTTP Request as Tool
```javascript
{
  name: "search_github_issues",
  description: "Search GitHub issues by keyword. Returns issue titles and URLs.",
  method: "GET",
  url: "https://api.github.com/search/issues",
  sendQuery: true,
  queryParameters: { "q": "={{ $json.query }}", "per_page": "5" }
}
```

**How it works**:
1. AI sees tool: `search_github_issues(query)`
2. AI decides to call it: `search_github_issues("bug in auth")`
3. n8n executes the HTTP Request
4. Result returned to AI Agent
5. AI processes result and responds

### Example: Database as Tool
```javascript
{
  name: "query_customers",
  description: "Query customer database. SELECT queries only. Search by email, name, or ID.",
  operation: "executeQuery",
  query: "={{ $json.sql }}"
  // ⚠️ Use read-only database user!
}
```

### Example: Code as Tool
```javascript
{
  name: "calculate_statistics",
  description: "Calculate statistics from a list of numbers. Input: comma-separated numbers."
}
// Code node:
const numbers = $input.first().json.input.split(',').map(Number);
return [{ json: {
  mean: numbers.reduce((a,b) => a+b) / numbers.length,
  min: Math.min(...numbers),
  max: Math.max(...numbers),
  count: numbers.length
}}];
```

### Pre-built Tool Nodes
Available in `@n8n/n8n-nodes-langchain`:
- Calculator Tool, Wikipedia Tool, Serper Tool (Google search), Wolfram Alpha Tool, Custom Tool

### Tool Description Best Practices

```javascript
// ❌ Vague — AI won't know when to use
description: "Get data"

// ✅ Specific — AI understands purpose and parameters
description: "Query customer orders by email address. Returns order ID, status, shipping info, and delivery date."
```

Tool descriptions are **critical** — the AI reads them to decide which tool to call.

---

## Memory Configuration

### Buffer Memory (store all messages)
```javascript
{
  memoryType: "bufferMemory",
  sessionKey: "={{ $json.body.session_id }}"    // Per-session memory
}
```
- Stores everything until cleared
- Can grow large for long conversations
- Good for short sessions

### Window Buffer Memory (RECOMMENDED)
```javascript
{
  memoryType: "windowBufferMemory",
  contextWindowLength: 10,                       // Last 10 messages
  sessionKey: "={{ $json.body.user_id }}"        // Per-user memory
}
```
- Bounded size (last N messages)
- Prevents context window overflow
- **Best for most use cases**

### Summary Memory
```javascript
{
  memoryType: "summaryMemory",
  sessionKey: "={{ $json.body.session_id }}"
}
```
- Summarizes older messages
- Good for very long conversations
- Loses details but keeps themes

### Session Keys
```javascript
// Per-user memory (persistent across sessions)
sessionKey: "={{ $json.body.user_id }}"

// Per-session memory (resets each session)
sessionKey: "={{ $json.body.session_id }}"

// Per-channel memory (shared context)
sessionKey: "={{ $json.body.channel_id }}"
```

---

## System Prompt Design

### Template
```
You are a [ROLE] for [CONTEXT].

You can:
- [CAPABILITY 1]
- [CAPABILITY 2]
- [CAPABILITY 3]

Guidelines:
- [BEHAVIORAL RULES]
- [SAFETY CONSTRAINTS]
- [RESPONSE STYLE]

Format:
- [OUTPUT FORMAT]
```

### Example: Customer Support
```
You are a customer support assistant for Acme Corp.

You can:
- Search the knowledge base for answers
- Look up customer orders and shipping status
- Create support tickets for complex issues

Guidelines:
- Be friendly and professional
- Verify customer identity before sharing order details
- If unsure, say so and offer to create a ticket
- Never share internal system details

Format:
- Keep responses concise
- Use bullet points for multiple items
```

### Example: Data Analyst
```
You are a data analyst with access to the company database.

You can:
- Query sales, customer, and product data
- Perform calculations and generate statistics
- Identify trends and anomalies

Guidelines:
- Write efficient SQL queries (always use LIMIT)
- Use read-only queries (SELECT only)
- Explain your analysis methodology
- Highlight important findings

Format:
- Provide numbers with context
- Include the SQL query used
```

---

## Common Use Cases

### 1. Conversational Chatbot
```
Webhook (chat) → AI Agent (GPT-4 + Tools + Memory) → Webhook Response
```

### 2. Document Q&A (RAG)
```
Setup: Files → Text Splitter → Embeddings → Vector Store
Query: Webhook → AI Agent (Model + Vector Store Tool + Memory) → Response
```

### 3. SQL Analyst
```
Webhook → AI Agent (Model + Postgres Tool + Code Tool) → Format → Response
```

### 4. Email Router
```
Email Trigger → AI Agent (categorize + route) → Jira (create ticket) → Email (auto-response)
```

### 5. DevOps Assistant
```
Slack → AI Agent (GitHub API Tool + Deploy Tool + DB Logger) → Slack Response
```

---

## Security

### 1. Read-Only Database Access
```sql
CREATE USER ai_agent_ro WITH PASSWORD 'secure';
GRANT SELECT ON public.* TO ai_agent_ro;
-- NO write access!
```

### 2. Validate Tool Inputs
```javascript
const query = $json.query;
if (query.toLowerCase().match(/drop|delete|update|insert|alter|truncate/)) {
  throw new Error('Write operations not allowed');
}
```

### 3. Rate Limiting
```
Webhook → IF (check user rate limit) → [OK] → AI Agent
                                     → [Exceeded] → 429 Response
```

### 4. Sanitize User Input
```javascript
const userInput = $json.body.message.trim().substring(0, 1000);
return [{ json: { sanitized: userInput } }];
```

### 5. Monitor Tool Usage
Log all tool calls. Alert on suspicious patterns (excessive queries, unusual tools).

---

## Performance

| Concern | Strategy |
|---------|----------|
| Model speed | GPT-3.5/Haiku for simple, GPT-4/Claude for complex |
| Context size | Window Buffer Memory (limit to 5-10 messages) |
| Tool overhead | Clear tool descriptions reduce unnecessary calls |
| Embedding cost | Embed documents once, query many times |
| Slow tools | Async processing, return immediate acknowledgment |

---

## Common Gotchas

### 1. Tools connected to wrong port
```
❌  HTTP Request → AI Agent (main port)     — Tool won't work
✅  HTTP Request ──[ai_tool]──→ AI Agent    — Correct!
```

### 2. Vague tool descriptions
```
❌  description: "Get data"                 — AI can't decide when to use
✅  description: "Query customer orders by email. Returns order ID, status, shipping."
```

### 3. No memory for conversations
```
❌  Each message is standalone              — No context!
✅  Window Buffer Memory via ai_memory port — Conversational context
```

### 4. Write access on database tools
```
❌  Full-access DB user as AI tool          — AI could DELETE data
✅  Read-only DB user as AI tool            — Safe
```

### 5. Unbounded tool responses
```
❌  SELECT * FROM large_table               — Exceeds token limit
✅  SELECT * FROM table LIMIT 10            — Bounded output
```

### 6. Missing session key for memory
```
❌  No sessionKey                           — All users share memory
✅  sessionKey: "={{ $json.body.user_id }}" — Per-user memory
```
