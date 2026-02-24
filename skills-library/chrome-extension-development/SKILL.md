---
name: chrome-extension-development
version: 2.0.0
description: Expert Chrome extension development with Manifest V3. Use when the user asks to build, debug, fix, migrate, or publish a Chrome extension, browser extension, or mentions Manifest V3, content scripts, background scripts, service workers for extensions, chrome.* APIs, popup pages, side panels, or Chrome Web Store. Also triggers for MV2→MV3 migration, extension permissions, content security policy for extensions, or declarativeNetRequest.
category: web-development
path: reference
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
env_vars: []
triggers: manual
---

# Chrome Extension Development (Manifest V3)

Expert guide for building production Chrome extensions with MV3. Claude already knows JavaScript/TypeScript fundamentals — this skill provides extension-specific architecture, constraints, and patterns that differ from standard web development.

## Critical MV3 Constraints

These hard constraints cause most extension failures. Enforce them in all generated code:

1. **Service Worker lifecycle**: Background scripts run as Service Workers. They terminate after ~30s of inactivity (5 min max execution). Never rely on global state persisting — always hydrate from `chrome.storage`.
2. **No remote code execution**: Cannot `eval()`, `new Function()`, or load remote scripts. All code must be bundled in the extension package.
3. **No persistent background pages**: MV3 replaced `"background": { "page": ... }` with `"background": { "service_worker": ... }`.
4. **Strict CSP**: Default is `script-src 'self'; object-src 'self'`. No inline scripts in HTML files. No `unsafe-eval`. See [reference/security.md](reference/security.md).
5. **`declarativeNetRequest` replaces `webRequest` blocking**: Cannot synchronously block/modify requests. Use static/dynamic rulesets instead. See [reference/mv3-patterns.md](reference/mv3-patterns.md#declarativenetrequest).
6. **DOM access requires offscreen documents**: Service workers have no DOM. Use `chrome.offscreen` API for DOM operations in background context.

## Starter Manifest Template

Always begin new extensions from this template. Adjust permissions to minimum required:

```json
{
  "manifest_version": 3,
  "name": "Extension Name",
  "version": "1.0.0",
  "description": "Clear, concise description under 132 chars",
  "permissions": [],
  "host_permissions": [],
  "background": {
    "service_worker": "background.js",
    "type": "module"
  },
  "action": {
    "default_popup": "popup.html",
    "default_icon": {
      "16": "icons/icon-16.png",
      "32": "icons/icon-32.png",
      "48": "icons/icon-48.png",
      "128": "icons/icon-128.png"
    }
  },
  "icons": {
    "16": "icons/icon-16.png",
    "48": "icons/icon-48.png",
    "128": "icons/icon-128.png"
  },
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"],
      "run_at": "document_idle"
    }
  ],
  "web_accessible_resources": [
    {
      "resources": ["assets/*"],
      "matches": ["<all_urls>"]
    }
  ],
  "content_security_policy": {
    "extension_pages": "script-src 'self'; object-src 'self'"
  }
}
```

### Key Manifest Fields

| Field | Notes |
|---|---|
| `permissions` | Only request what's needed. `activeTab` over `tabs` when possible. See [reference/security.md#permissions](reference/security.md). |
| `host_permissions` | Separate from `permissions` in MV3. Triggers install warning. Use optional permissions when feasible. |
| `optional_permissions` | Request at runtime with `chrome.permissions.request()` — better UX. |
| `background.type` | Set `"module"` to use ES module `import/export` in service worker. |
| `content_scripts.run_at` | `document_idle` (default, safest), `document_start`, `document_end`. |

## Architecture

### Component Communication

```
┌─────────────┐    chrome.runtime     ┌──────────────────┐
│   Popup      │◄────────────────────►│  Service Worker   │
│  (popup.html)│    .sendMessage()     │  (background.js)  │
└──────┬───────┘                       └────────┬──────────┘
       │                                        │
       │  chrome.storage                chrome.tabs
       │  (shared state)               .sendMessage()
       │                                        │
       ▼                                        ▼
┌──────────────────────────────────────────────────────┐
│              Content Script (content.js)               │
│         (runs in page context, isolated world)         │
└──────────────────────────────────────────────────────┘
       │
       │ window.postMessage (if needed)
       ▼
┌──────────────────────────────────────────────────────┐
│              Web Page (page context)                    │
└──────────────────────────────────────────────────────┘
```

### Messaging Patterns

**One-shot message (popup ↔ service worker):**
```js
// Sender
const response = await chrome.runtime.sendMessage({ type: 'GET_DATA', payload: { id: 123 } });

// Receiver (background.js)
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'GET_DATA') {
    fetchData(message.payload.id).then(sendResponse);
    return true; // Keep channel open for async response
  }
});
```

**Service worker → content script:**
```js
const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
const response = await chrome.tabs.sendMessage(tab.id, { type: 'EXTRACT_TEXT' });
```

**Long-lived connection (for streaming/ongoing communication):**
```js
// Content script
const port = chrome.runtime.connect({ name: 'stream' });
port.onMessage.addListener((msg) => { /* handle */ });
port.postMessage({ type: 'START_STREAM' });

// Background
chrome.runtime.onConnect.addListener((port) => {
  if (port.name === 'stream') {
    port.onMessage.addListener((msg) => { /* handle */ });
  }
});
```

### State Management with Storage

Service workers restart — never use global variables for state:

```js
// ❌ WRONG — state lost on SW restart
let count = 0;
chrome.action.onClicked.addListener(() => { count++; });

// ✅ CORRECT — persist to storage
chrome.action.onClicked.addListener(async () => {
  const { count = 0 } = await chrome.storage.local.get('count');
  await chrome.storage.local.set({ count: count + 1 });
});
```

**Storage options:**
| API | Quota | Sync | Use case |
|---|---|---|---|
| `chrome.storage.local` | ~10 MB | No | Large data, local-only |
| `chrome.storage.sync` | 100 KB total, 8 KB/item | Yes | User preferences, small config |
| `chrome.storage.session` | ~10 MB | No | Ephemeral data, cleared on restart |

## Project Structure

```
extension/
├── manifest.json
├── background.js          # Service worker
├── popup/
│   ├── popup.html         # No inline scripts!
│   ├── popup.js
│   └── popup.css
├── content/
│   └── content.js         # Content script(s)
├── sidepanel/             # Optional side panel
│   ├── sidepanel.html
│   └── sidepanel.js
├── options/               # Optional options page
│   ├── options.html
│   └── options.js
├── icons/
│   ├── icon-16.png
│   ├── icon-32.png
│   ├── icon-48.png
│   └── icon-128.png
├── _locales/              # If i18n needed
│   └── en/
│       └── messages.json
└── assets/                # web_accessible_resources
```

## Build Setup (TypeScript + Bundler)

For non-trivial extensions, use a bundler. Minimal `vite.config.ts`:

```ts
import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  build: {
    rollupOptions: {
      input: {
        background: resolve(__dirname, 'src/background.ts'),
        content: resolve(__dirname, 'src/content.ts'),
        popup: resolve(__dirname, 'src/popup/popup.html'),
      },
      output: {
        entryFileNames: '[name].js',
        chunkFileNames: '[name].js',
        assetFileNames: '[name].[ext]',
      },
    },
    outDir: 'dist',
    emptyOutDir: true,
  },
});
```

## Quick Decision Trees

**Which API for scheduled tasks?**
- Repeating timer → `chrome.alarms` (minimum 1 min interval)
- One-shot delay → `chrome.alarms.create('name', { delayInMinutes: 1 })`
- Never use `setTimeout`/`setInterval` in service workers (lost on termination)

**Which API for request interception?**
- Block/redirect requests → `declarativeNetRequest` (static rules or dynamic)
- Observe requests (read-only) → `webRequest` (still available for observing)
- Modify headers → `declarativeNetRequest` with `modifyHeaders` action

**How to access DOM from background?**
- Inject content script → `chrome.scripting.executeScript()`
- Need background DOM (parsing, audio, etc.) → `chrome.offscreen.createDocument()`

**Side Panel vs Popup?**
- Quick actions, small UI → Popup (closes when clicking away)
- Persistent UI alongside page → Side Panel (`chrome.sidePanel`)

## Reference Files

Load these as needed based on the task:

- **[reference/mv3-patterns.md](reference/mv3-patterns.md)**: Detailed code patterns for declarativeNetRequest, offscreen documents, alarms, scripting injection, context menus, side panels, and MV2→MV3 migration guide.
- **[reference/security.md](reference/security.md)**: Content Security Policy details, permissions strategy, XSS prevention, secure messaging, data handling, and web_accessible_resources hardening.
- **[reference/testing-publishing.md](reference/testing-publishing.md)**: Testing strategies, debugging techniques, Chrome Web Store submission checklist, privacy policy requirements, and update mechanisms.

## Common Pitfalls Checklist

Before finalizing any extension, verify:

- [ ] No `eval()`, `new Function()`, or inline scripts in HTML
- [ ] Service worker handles restart gracefully (no global mutable state)
- [ ] All async `sendMessage` handlers `return true`
- [ ] `chrome.alarms` used instead of `setTimeout`/`setInterval`
- [ ] Permissions are minimal (prefer `activeTab` + `optional_permissions`)
- [ ] `web_accessible_resources` scoped to specific matches, not `<all_urls>` unless necessary
- [ ] Content scripts handle page navigation / SPA route changes
- [ ] Error handling wraps all chrome.* API calls
- [ ] Icons provided in all required sizes (16, 32, 48, 128)
