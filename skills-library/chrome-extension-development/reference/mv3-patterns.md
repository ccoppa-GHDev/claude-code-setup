# MV3 Patterns Reference

Detailed code patterns for Manifest V3 Chrome extension APIs.

## Table of Contents
- [declarativeNetRequest](#declarativenetrequest)
- [Offscreen Documents](#offscreen-documents)
- [chrome.alarms](#chromealarms)
- [chrome.scripting (Programmatic Injection)](#chromescripting)
- [Context Menus](#context-menus)
- [Side Panel](#side-panel)
- [chrome.storage Reactive Patterns](#chromestorage-reactive-patterns)
- [Internationalization (i18n)](#internationalization)
- [Options Page](#options-page)
- [MV2 → MV3 Migration Guide](#mv2--mv3-migration)

---

## declarativeNetRequest

Replaces blocking `webRequest`. Uses static JSON rulesets and/or dynamic rules.

### Static Rules (declared in manifest)

**manifest.json:**
```json
{
  "permissions": ["declarativeNetRequest"],
  "declarative_net_request": {
    "rule_resources": [
      {
        "id": "ruleset_1",
        "enabled": true,
        "path": "rules/block-trackers.json"
      }
    ]
  }
}
```

**rules/block-trackers.json:**
```json
[
  {
    "id": 1,
    "priority": 1,
    "action": { "type": "block" },
    "condition": {
      "urlFilter": "||tracker.example.com",
      "resourceTypes": ["script", "image", "xmlhttprequest"]
    }
  },
  {
    "id": 2,
    "priority": 1,
    "action": {
      "type": "redirect",
      "redirect": { "url": "https://safe.example.com/pixel.gif" }
    },
    "condition": {
      "urlFilter": "||ads.example.com/pixel",
      "resourceTypes": ["image"]
    }
  },
  {
    "id": 3,
    "priority": 1,
    "action": {
      "type": "modifyHeaders",
      "responseHeaders": [
        { "header": "X-Frame-Options", "operation": "remove" }
      ]
    },
    "condition": {
      "urlFilter": "||example.com",
      "resourceTypes": ["sub_frame"]
    }
  }
]
```

### Dynamic Rules (added at runtime)

```js
// Add rule
await chrome.declarativeNetRequest.updateDynamicRules({
  addRules: [
    {
      id: 1000,
      priority: 1,
      action: { type: 'block' },
      condition: {
        urlFilter: userBlockedDomain,
        resourceTypes: ['main_frame', 'sub_frame', 'script'],
      },
    },
  ],
  removeRuleIds: [1000], // Remove existing rule with same ID first
});

// List current dynamic rules
const rules = await chrome.declarativeNetRequest.getDynamicRules();

// Remove rules
await chrome.declarativeNetRequest.updateDynamicRules({
  removeRuleIds: [1000, 1001],
});
```

### Rule Condition Syntax

| Field | Example | Notes |
|---|---|---|
| `urlFilter` | `"||example.com"` | `||` = any scheme. `*` = wildcard. `^` = separator. |
| `regexFilter` | `".*\\.js$"` | Use instead of urlFilter for regex. Max 1 per rule. |
| `resourceTypes` | `["script", "image"]` | Required. See [full list](https://developer.chrome.com/docs/extensions/reference/api/declarativeNetRequest#type-ResourceType). |
| `domains` | `["mysite.com"]` | Only match when initiated from these domains. |
| `excludedDomains` | `["safe.com"]` | Never match from these domains. |

**Limits:** 5000 static rules per ruleset, 30000 total. 5000 dynamic rules. 1000 regex rules.

---

## Offscreen Documents

Access DOM APIs from the background (service worker) context.

**manifest.json:**
```json
{ "permissions": ["offscreen"] }
```

**background.js:**
```js
async function ensureOffscreenDocument() {
  const existingContexts = await chrome.runtime.getContexts({
    contextType: 'OFFSCREEN_DOCUMENT',
  });
  if (existingContexts.length > 0) return;

  await chrome.offscreen.createDocument({
    url: 'offscreen/offscreen.html',
    reasons: ['DOM_PARSER'],       // Also: AUDIO_PLAYBACK, CLIPBOARD, etc.
    justification: 'Parse HTML content',
  });
}

// Use messaging to interact with the offscreen document
async function parseHTML(html) {
  await ensureOffscreenDocument();
  return chrome.runtime.sendMessage({ type: 'PARSE_HTML', html });
}
```

**offscreen/offscreen.html:**
```html
<!DOCTYPE html>
<script src="offscreen.js"></script>
```

**offscreen/offscreen.js:**
```js
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'PARSE_HTML') {
    const doc = new DOMParser().parseFromString(message.html, 'text/html');
    const title = doc.querySelector('title')?.textContent ?? '';
    sendResponse({ title });
    return true;
  }
});
```

**Valid reasons:** `TESTING`, `AUDIO_PLAYBACK`, `IFRAME_SCRIPTING`, `DOM_SCRAPING`, `BLOBS`, `DOM_PARSER`, `USER_MEDIA`, `DISPLAY_MEDIA`, `WEB_RTC`, `CLIPBOARD`, `LOCAL_STORAGE`, `WORKERS`, `BATTERY_STATUS`, `MATCH_MEDIA`, `GEOLOCATION`.

---

## chrome.alarms

Use instead of `setTimeout`/`setInterval` in service workers.

```js
// Create alarms
chrome.alarms.create('refresh-data', { periodInMinutes: 30 });
chrome.alarms.create('one-time-task', { delayInMinutes: 5 });
chrome.alarms.create('daily-cleanup', {
  when: Date.now() + 24 * 60 * 60 * 1000,  // First run in 24h
  periodInMinutes: 24 * 60,                  // Then every 24h
});

// Listen
chrome.alarms.onAlarm.addListener(async (alarm) => {
  switch (alarm.name) {
    case 'refresh-data':
      await refreshData();
      break;
    case 'daily-cleanup':
      await cleanupOldEntries();
      break;
  }
});

// Cancel
await chrome.alarms.clear('refresh-data');
await chrome.alarms.clearAll();
```

**manifest.json:** `"permissions": ["alarms"]`

**Minimum interval:** 1 minute in production. 30 seconds during development (loaded unpacked).

---

## chrome.scripting

Programmatically inject scripts/CSS into pages. Replaces MV2 `chrome.tabs.executeScript`.

**manifest.json:**
```json
{
  "permissions": ["scripting", "activeTab"]
}
```

### Inject a function

```js
async function injectIntoActiveTab() {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });

  const results = await chrome.scripting.executeScript({
    target: { tabId: tab.id },
    func: (selector) => {
      const el = document.querySelector(selector);
      return el?.textContent ?? null;
    },
    args: ['h1'],   // Arguments passed to func
  });

  console.log(results[0]?.result); // The h1 text
}
```

### Inject a file

```js
await chrome.scripting.executeScript({
  target: { tabId: tab.id, allFrames: true },
  files: ['content/injected.js'],
});
```

### Inject CSS

```js
await chrome.scripting.insertCSS({
  target: { tabId: tab.id },
  css: '.ad-banner { display: none !important; }',
});

// Or from file
await chrome.scripting.insertCSS({
  target: { tabId: tab.id },
  files: ['styles/injected.css'],
});
```

### Register content scripts dynamically

```js
await chrome.scripting.registerContentScripts([
  {
    id: 'dynamic-script',
    matches: ['https://example.com/*'],
    js: ['content/dynamic.js'],
    runAt: 'document_idle',
    persistAcrossSessions: true,
  },
]);

// Unregister
await chrome.scripting.unregisterContentScripts({ ids: ['dynamic-script'] });
```

---

## Context Menus

**manifest.json:** `"permissions": ["contextMenus"]`

```js
// Create in service worker install/startup
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: 'lookup-selection',
    title: 'Look up "%s"',          // %s = selected text
    contexts: ['selection'],
  });

  chrome.contextMenus.create({
    id: 'save-image',
    title: 'Save to collection',
    contexts: ['image'],
  });

  // Nested menus
  chrome.contextMenus.create({ id: 'parent', title: 'My Extension', contexts: ['page'] });
  chrome.contextMenus.create({ id: 'child1', parentId: 'parent', title: 'Option A', contexts: ['page'] });
  chrome.contextMenus.create({ id: 'child2', parentId: 'parent', title: 'Option B', contexts: ['page'] });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  switch (info.menuItemId) {
    case 'lookup-selection':
      handleLookup(info.selectionText, tab);
      break;
    case 'save-image':
      handleSaveImage(info.srcUrl, tab);
      break;
  }
});
```

---

## Side Panel

Persistent UI that stays open alongside web pages.

**manifest.json:**
```json
{
  "permissions": ["sidePanel"],
  "side_panel": {
    "default_path": "sidepanel/sidepanel.html"
  }
}
```

```js
// Open programmatically (requires user gesture)
chrome.sidePanel.open({ windowId: tab.windowId });

// Set panel per-tab
chrome.sidePanel.setOptions({
  tabId: tab.id,
  path: 'sidepanel/detail.html',
  enabled: true,
});

// Disable for specific tabs
chrome.sidePanel.setOptions({ tabId: tab.id, enabled: false });

// Set behavior — open on action click instead of popup
chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true });
```

---

## chrome.storage Reactive Patterns

Listen for storage changes across all extension components:

```js
// Any component (popup, content script, background)
chrome.storage.onChanged.addListener((changes, areaName) => {
  if (areaName !== 'local') return;

  for (const [key, { oldValue, newValue }] of Object.entries(changes)) {
    console.log(`${key}: ${oldValue} → ${newValue}`);
    if (key === 'theme') updateTheme(newValue);
  }
});
```

### Batch operations

```js
// Set multiple values atomically
await chrome.storage.local.set({
  settings: { theme: 'dark', fontSize: 14 },
  lastUpdated: Date.now(),
});

// Get with defaults
const { settings = { theme: 'light', fontSize: 12 } } = await chrome.storage.local.get('settings');
```

---

## Internationalization

**_locales/en/messages.json:**
```json
{
  "extName": {
    "message": "My Extension",
    "description": "Extension display name"
  },
  "buttonSave": {
    "message": "Save",
    "description": "Save button label"
  },
  "greeting": {
    "message": "Hello, $USER$!",
    "placeholders": {
      "user": { "content": "$1", "example": "Alice" }
    }
  }
}
```

**Usage:**
```js
// In JS
chrome.i18n.getMessage('buttonSave');             // "Save"
chrome.i18n.getMessage('greeting', ['Alice']);      // "Hello, Alice!"

// In manifest.json
"name": "__MSG_extName__"

// In HTML
<span data-i18n="buttonSave"></span>

// Helper to localize HTML
document.querySelectorAll('[data-i18n]').forEach((el) => {
  el.textContent = chrome.i18n.getMessage(el.dataset.i18n);
});
```

**manifest.json:** `"default_locale": "en"`

---

## Options Page

**manifest.json:**
```json
{
  "options_ui": {
    "page": "options/options.html",
    "open_in_tab": false
  }
}
```

Open programmatically: `chrome.runtime.openOptionsPage();`

---

## MV2 → MV3 Migration

| MV2 | MV3 Replacement |
|---|---|
| `"manifest_version": 2` | `"manifest_version": 3` |
| `"background": { "scripts": [...] }` | `"background": { "service_worker": "bg.js" }` |
| `"browser_action"` / `"page_action"` | `"action"` (unified) |
| `chrome.browserAction.*` | `chrome.action.*` |
| `chrome.tabs.executeScript()` | `chrome.scripting.executeScript()` |
| `chrome.tabs.insertCSS()` | `chrome.scripting.insertCSS()` |
| `webRequest` blocking | `declarativeNetRequest` |
| `"permissions": ["https://..."]` | `"host_permissions": ["https://..."]` |
| `"content_security_policy": "..."` | `"content_security_policy": { "extension_pages": "..." }` |
| `"web_accessible_resources": [...]` | `"web_accessible_resources": [{ "resources": [...], "matches": [...] }]` |
| Persistent background page | Service worker (non-persistent) |
| `localStorage` in background | `chrome.storage.session` or `chrome.storage.local` |
| `XMLHttpRequest` in background | `fetch()` |
| `chrome.extension.getURL()` | `chrome.runtime.getURL()` |

### Migration Checklist

1. Update `manifest_version` to 3
2. Convert background page to service worker — remove all DOM usage
3. Replace global state with `chrome.storage`
4. Replace `setTimeout`/`setInterval` with `chrome.alarms`
5. Move host patterns from `permissions` to `host_permissions`
6. Replace `browserAction`/`pageAction` with `action`
7. Replace `tabs.executeScript` with `scripting.executeScript`
8. Replace blocking `webRequest` with `declarativeNetRequest`
9. Update CSP format to object syntax
10. Scope `web_accessible_resources` with `matches`
11. Replace `localStorage` with `chrome.storage.session`
12. Test service worker restart behavior (terminate via `chrome://serviceworker-internals`)
