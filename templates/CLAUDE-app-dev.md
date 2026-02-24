# Project: {{PROJECT_NAME}}

## What This Is
<!-- 1-2 sentences: what the app does and who it's for -->

## Architecture
- **Frontend**: {{e.g., Next.js 14 App Router, React, Tailwind CSS}}
- **Backend**: {{e.g., Next.js API routes / Supabase Edge Functions}}
- **Database**: {{e.g., Supabase PostgreSQL with Row Level Security}}
- **Auth**: {{e.g., Supabase Auth with OAuth providers}}
- **Deployment**: {{e.g., Vercel}}

## Key Directories
- `src/app/` — Pages and route handlers (App Router)
- `src/components/` — Reusable React components
- `src/lib/` — Utilities, Supabase client, shared logic
- `supabase/migrations/` — Database migrations (source of truth for schema)

## Commands
```bash
npm run dev          # Start dev server
npm run build        # Production build — ALWAYS run before saying "done"
npm run typecheck    # TypeScript check — run after code changes
npm run test         # Run test suite
npm run lint         # Lint check
```

## Verification
IMPORTANT: After any code change, run `npm run build` to verify. A clean build is the minimum bar before marking work complete. If tests exist for the area you changed, run those too.

## Patterns
- Follow existing patterns in the codebase — search before inventing
- For complex features: read relevant code → plan → implement → verify
- Database changes require a migration file in `supabase/migrations/`
- For deeper architecture docs, see `docs/` directory if it exists

## Error Recovery
When something breaks: read the error → fix the root cause → verify the fix → if you learned something reusable, suggest a CLAUDE.md update via `#`
