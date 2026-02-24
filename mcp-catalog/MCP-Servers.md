# MCP Server Catalog

This file defines available MCP servers for /begin to recommend.

**Critical Rule:** Keep under 10 MCP servers enabled per project. Your 200k context window can shrink to 70k with too many tools active.

---

## Tier 1: Essential (Auto-selected for all projects)

### GitHub
**Description:** Integration with GitHub Issues, Pull Requests, branches, and CI/CD workflows.
**GitHub:** https://github.com/github/github-mcp-server
**Context Cost:** Medium

```bash
claude mcp add github --scope project -- npx -y @modelcontextprotocol/server-github
```

**Environment Variables:**
| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_TOKEN` | Yes | Personal access token with repo scope |

**How to get it:** GitHub → Settings → Developer Settings → Personal Access Tokens → Generate new token → Select `repo` scope

---

### Sequential Thinking
**Description:** Structured sequential thinking for breaking down complex problems, iteratively refining solutions, and exploring multiple reasoning paths.
**GitHub:** https://github.com/modelcontextprotocol/servers/tree/HEAD/src/sequentialthinking
**Context Cost:** Low

```bash
claude mcp add sequential-thinking --scope project -- npx -y @modelcontextprotocol/server-sequential-thinking
```

**Environment Variables:** None required.

---

### Context7
**Description:** Up-to-date library and framework documentation with intelligent project ranking. Connects to Context7.com's documentation database.
**GitHub:** https://github.com/upstash/context7
**Context Cost:** Medium

```bash
claude mcp add context7 --scope project --transport http --header "CONTEXT7_API_KEY: ${CONTEXT7_API_KEY}" https://mcp.context7.com/mcp
```

**Environment Variables:**
| Variable | Required | Description |
|----------|----------|-------------|
| `CONTEXT7_API_KEY` | Yes | Context7 API key |

**How to get it:** https://context7.com → Sign up → Generate API key

---

## Tier 2: Recommended (Based on project needs)

### Brave Search
**Description:** Web search, local business search, image/video/news search, and summarization with advanced filtering and content safety controls.
**GitHub:** https://github.com/brave/brave-search-mcp-server
**Context Cost:** Medium
**Recommend when:** web search, research, current information, documentation lookup, troubleshooting

```bash
claude mcp add brave-search --scope project -e BRAVE_API_KEY=${BRAVE_API_KEY} -- npx -y @modelcontextprotocol/server-brave-search
```

**Environment Variables:**
| Variable | Required | Description |
|----------|----------|-------------|
| `BRAVE_API_KEY` | Yes | Brave Search API key |

**How to get it:** https://brave.com/search/api/ → Get Started → Create account → Generate API key

---

### Memory Server
**Description:** Persistent knowledge storage across sessions. Remember context, decisions, and learned information.
**GitHub:** https://github.com/modelcontextprotocol/servers/tree/main/src/memory
**Context Cost:** Low
**Recommend when:** long-term context, memory, persistence, cross-session, remember decisions

```bash
claude mcp add memory --scope project -- npx -y @modelcontextprotocol/server-memory
```

**Environment Variables:** None required.

---

### PostgreSQL
**Description:** Access and analyze Postgres databases with read-only queries. Schema inspection and data exploration.
**GitHub:** https://github.com/modelcontextprotocol/servers-archived/tree/HEAD/src/postgres
**Context Cost:** Medium
**Recommend when:** postgres, postgresql, database, SQL, data queries, schema

```bash
claude mcp add postgres --scope project -e DATABASE_URL=${DATABASE_URL} -- npx -y @modelcontextprotocol/server-postgres
```

**Environment Variables:**
| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string |

**How to get it:** Format: `postgresql://user:password@host:5432/database`

---

## Tier 3: Specialized (Enable as needed)

### Playwright Browser Automation
**Description:** Web browser control for navigating websites, capturing page snapshots, interacting with elements, and taking screenshots.
**GitHub:** https://github.com/microsoft/playwright-mcp
**Context Cost:** High
**Recommend when:** browser automation, e2e testing, screenshots, web scraping, UI testing

```bash
claude mcp add playwright --scope project -- npx @playwright/mcp@latest
```

**Environment Variables:** None required.

---

### Chrome DevTools
**Description:** Direct Chrome browser control through DevTools for debugging, performance analysis, accessibility testing, and automation.
**GitHub:** https://github.com/chromedevtools/chrome-devtools-mcp
**Context Cost:** High
**Recommend when:** browser debugging, performance analysis, accessibility testing, Chrome automation

```bash
claude mcp add chrome-devtools --scope project -- npx chrome-devtools-mcp@latest
```

**Environment Variables:** None required.

**Notes:** For authenticated sites, launch Chrome with debug profile:
```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/.chrome-debug-profile"
```

---

### Supabase
**Description:** Manage Supabase databases, execute SQL queries, apply migrations, and handle configurations through natural language.
**GitHub:** https://github.com/supabase-community/supabase-mcp
**Context Cost:** Medium
**Recommend when:** supabase, database, postgres, auth, authentication, storage, edge functions

```bash
claude mcp add supabase --scope project --transport http https://mcp.supabase.com/mcp
```

**Environment Variables:**
| Variable | Required | Description |
|----------|----------|-------------|
| `SUPABASE_URL` | Yes | Your Supabase project URL |
| `SUPABASE_SERVICE_KEY` | Yes | Service role key (not anon key) |

**How to get it:** Supabase Dashboard → Project Settings → API

---

### n8n Workflow Automation
**Description:** Conversational access to 525+ n8n nodes including AI-capable nodes and triggers. Natural language workflow creation and management.
**GitHub:** https://github.com/czlonkowski/n8n-mcp
**Context Cost:** High
**Recommend when:** n8n, workflow automation, integrations, automation, triggers

```bash
claude mcp add n8n-mcp --scope project -e MCP_MODE=stdio -e LOG_LEVEL=error -e DISABLE_CONSOLE_OUTPUT=true -- npx n8n-mcp
```

**Environment Variables:**
| Variable | Required | Description |
|----------|----------|-------------|
| `MCP_MODE` | Yes | Set to `stdio` |
| `LOG_LEVEL` | No | Set to `error` to reduce noise |
| `DISABLE_CONSOLE_OUTPUT` | No | Set to `true` for cleaner output |

---

### FireCrawl
**Description:** Advanced web scraping for extracting structured data from complex websites.
**GitHub:** https://github.com/firecrawl/firecrawl-mcp-server
**Context Cost:** Medium
**Recommend when:** web scraping, data extraction, crawling, structured data

```bash
claude mcp add firecrawl --scope project -e FIRECRAWL_API_KEY=${FIRECRAWL_API_KEY} -- npx -y firecrawl-mcp
```

**Environment Variables:**
| Variable | Required | Description |
|----------|----------|-------------|
| `FIRECRAWL_API_KEY` | Yes | FireCrawl API key |

**How to get it:** https://firecrawl.dev → Sign up → Generate API key

---

### GoHighLevel
**Description:** Integration with GoHighLevel/LeadConnector CRM platform for managing contacts, pipelines, and automations.
**GitHub:** (Proprietary - no public repo)
**Context Cost:** Medium
**Recommend when:** GoHighLevel, GHL, LeadConnector, CRM, marketing automation

```bash
claude mcp add ghl --scope project --transport http --header "Authorization: Bearer ${GHL_API_TOKEN}" --header "locationId: ${GHL_LOCATION_ID}" https://services.leadconnectorhq.com/mcp/
```

**Environment Variables:**
| Variable | Required | Description |
|----------|----------|-------------|
| `GHL_API_TOKEN` | Yes | GoHighLevel API token |
| `GHL_LOCATION_ID` | Yes | Sub-account/location ID |

**How to get it:** GoHighLevel → Settings → API Keys

---

### Next.js DevTools
**Description:** Next.js development tools and utilities for coding agents. Route inspection, build analysis, and development helpers.
**GitHub:** https://github.com/vercel/next-devtools-mcp
**Context Cost:** Medium
**Recommend when:** Next.js, Vercel, React, SSR, app router, pages router

```bash
claude mcp add next-devtools --scope project -- npx next-devtools-mcp@latest
```

**Environment Variables:** None required.

---

## Adding New Servers

To add a new MCP server, append to the appropriate tier using this format:

```markdown
### Server Name
**Description:** What the server does.
**GitHub:** https://github.com/...
**Context Cost:** Low | Medium | High
**Recommend when:** keyword1, keyword2, keyword3

\`\`\`bash
claude mcp add server-name --scope project -- npx package-name
\`\`\`

**Environment Variables:**
| Variable | Required | Description |
|----------|----------|-------------|
| `VAR_NAME` | Yes/No | What it's for |

**How to get it:** Instructions
```
