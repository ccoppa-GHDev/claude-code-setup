# Testing & Publishing Reference

Debugging, testing, and Chrome Web Store submission guide.

## Table of Contents
- [Debugging Techniques](#debugging-techniques)
- [Testing Strategies](#testing-strategies)
- [Chrome Web Store Submission](#chrome-web-store-submission)
- [Privacy Policy Requirements](#privacy-policy-requirements)
- [Update & Versioning](#update--versioning)
- [Performance Monitoring](#performance-monitoring)

---

## Debugging Techniques

### Inspecting Extension Components

| Component | How to inspect |
|---|---|
| Popup | Right-click popup → Inspect |
| Service worker | `chrome://extensions` → "Inspect views: service worker" |
| Content script | Page DevTools → Sources → Content scripts |
| Options page | Right-click → Inspect |
| Side panel | Right-click panel → Inspect |
| Offscreen document | `chrome://extensions` → "Inspect views: offscreen.html" |

### Service Worker Debugging

```
chrome://extensions        → View logs, errors, restart SW
chrome://serviceworker-internals → Force terminate SW (test restart)
```

**Common debugging pattern — add lifecycle logging:**
```js
// background.js
console.log('[SW] Script evaluated at', new Date().toISOString());

chrome.runtime.onInstalled.addListener((details) => {
  console.log('[SW] onInstalled:', details.reason); // install, update, chrome_update
});

chrome.runtime.onStartup.addListener(() => {
  console.log('[SW] onStartup — browser launched');
});

self.addEventListener('activate', () => {
  console.log('[SW] Activated');
});
```

### Error Handling Pattern

Wrap all chrome.* API calls:

```js
async function safeStorageGet(keys) {
  try {
    return await chrome.storage.local.get(keys);
  } catch (error) {
    console.error('[Storage] Get failed:', error.message);
    return {};
  }
}

// Global error handler for service worker
self.addEventListener('error', (event) => {
  console.error('[SW Error]', event.message, event.filename, event.lineno);
});

self.addEventListener('unhandledrejection', (event) => {
  console.error('[SW Unhandled Promise]', event.reason);
});
```

### Debugging Content Scripts

```js
// Check if content script is loaded
console.log('[CS] Content script loaded on:', window.location.href);

// Debug message flow
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  console.log('[CS] Received message:', msg.type, 'from:', sender);
  // ...
});
```

### Common Issues & Fixes

| Symptom | Cause | Fix |
|---|---|---|
| Service worker shows "inactive" | Normal termination | Design for restart — persist state |
| `sendMessage` returns `undefined` | Handler didn't `return true` for async | Add `return true` to async handlers |
| Content script not injecting | URL pattern mismatch or page loaded before script | Check `matches`, try `run_at: "document_start"` |
| "Extension context invalidated" | Extension updated while content script was running | Detect and reload: catch `chrome.runtime.lastError` |
| Popup closes unexpectedly | Clicked outside popup | Expected behavior — save state to storage before close |
| API calls fail silently | Missing permission | Check `chrome.runtime.lastError` after every API call |

---

## Testing Strategies

### Manual Testing Checklist

1. **Fresh install** — Load unpacked, verify onInstalled fires
2. **Extension update** — Increment version, reload, verify migration
3. **Service worker restart** — Kill via `chrome://serviceworker-internals`, verify state recovery
4. **Permission flow** — Test optional permission request/revoke
5. **Cross-browser** — Test in Edge (Chromium-based)
6. **Incognito mode** — Enable "Allow in incognito", test isolation
7. **Multiple tabs** — Verify behavior with many tabs open
8. **Error states** — Network failure, storage full, invalid data

### Unit Testing with Jest/Vitest

Mock chrome.* APIs:

```js
// __mocks__/chrome.js
global.chrome = {
  storage: {
    local: {
      get: vi.fn().mockResolvedValue({}),
      set: vi.fn().mockResolvedValue(undefined),
    },
    onChanged: {
      addListener: vi.fn(),
    },
  },
  runtime: {
    sendMessage: vi.fn(),
    onMessage: {
      addListener: vi.fn(),
    },
    id: 'test-extension-id',
  },
  tabs: {
    query: vi.fn().mockResolvedValue([{ id: 1, url: 'https://example.com' }]),
    sendMessage: vi.fn(),
  },
  alarms: {
    create: vi.fn(),
    onAlarm: { addListener: vi.fn() },
  },
};
```

```js
// storage-utils.test.js
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { saveSettings, getSettings } from '../src/storage-utils';

describe('saveSettings', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('saves settings to chrome.storage.local', async () => {
    const settings = { theme: 'dark', fontSize: 14 };
    await saveSettings(settings);

    expect(chrome.storage.local.set).toHaveBeenCalledWith({ settings });
  });

  it('returns defaults when storage is empty', async () => {
    chrome.storage.local.get.mockResolvedValue({});
    const result = await getSettings();

    expect(result).toEqual({ theme: 'light', fontSize: 12 });
  });
});
```

### Integration Testing with Puppeteer

```js
import puppeteer from 'puppeteer';

const browser = await puppeteer.launch({
  headless: false,
  args: [
    `--disable-extensions-except=${extensionPath}`,
    `--load-extension=${extensionPath}`,
  ],
});

// Get extension ID
const targets = await browser.targets();
const extensionTarget = targets.find(t => t.type() === 'service_worker');
const extensionId = extensionTarget.url().split('/')[2];

// Test popup
const popupPage = await browser.newPage();
await popupPage.goto(`chrome-extension://${extensionId}/popup/popup.html`);
await popupPage.click('#save-button');

// Test content script interaction
const page = await browser.newPage();
await page.goto('https://example.com');
const result = await page.evaluate(() => {
  return document.querySelector('.extension-injected')?.textContent;
});
```

---

## Chrome Web Store Submission

### Pre-Submission Checklist

**Required assets:**
- [ ] Extension icon: 128x128 PNG
- [ ] Store icon: 128x128 PNG (listed in manifest)
- [ ] Screenshots: 1280x800 or 640x400 (min 1, max 5)
- [ ] Promotional images (optional): Small tile 440x280
- [ ] Detailed description (up to 16,000 chars)
- [ ] Short description (up to 132 chars) — same as manifest `description`

**Technical requirements:**
- [ ] No obfuscated/minified code (source maps or readable build)
- [ ] No remote code execution
- [ ] Permissions justified (you'll be asked during review)
- [ ] All declared permissions are actually used
- [ ] `activeTab` preferred over `<all_urls>` where possible
- [ ] Privacy policy URL (required if accessing user data or using remote servers)

**Manifest requirements:**
- [ ] `version` follows semver or Chrome's 4-part format (e.g., `1.0.0` or `1.0.0.1`)
- [ ] `name` ≤ 45 characters
- [ ] `description` ≤ 132 characters, no keyword stuffing
- [ ] All icon sizes provided (16, 32, 48, 128)

### Store Listing Tips

- First sentence of description should explain what the extension does
- Use bullet points for features
- Include "How to use" section
- Mention permissions and why they're needed
- Don't mention competing extensions by name
- Keep screenshots up to date

### Review Process

- Automated scan: minutes to hours
- Manual review: 1-3 business days (first submission may take longer)
- Common rejection reasons:
  1. Requesting unnecessary permissions
  2. Missing or inadequate privacy policy
  3. Deceptive functionality or description
  4. Remote code execution
  5. Single-purpose policy violation

---

## Privacy Policy Requirements

**Required when your extension:**
- Collects personal data (including browsing activity)
- Uses any `host_permissions`
- Sends data to external servers
- Uses analytics or tracking

**Must include:**
- What data is collected
- How data is used
- Whether data is shared with third parties
- How users can delete their data
- Data retention period
- Contact information

**Template structure:**
```
1. What information does this extension collect?
2. How is this information used?
3. Is data shared with third parties?
4. How is data stored and protected?
5. How can users manage or delete their data?
6. Changes to this policy
7. Contact information
```

Host the privacy policy on a public URL — GitHub Pages, your website, or Notion.

---

## Update & Versioning

### Auto-update mechanism

Chrome automatically updates extensions every few hours. To trigger faster:
1. Update `version` in manifest.json
2. Upload new `.zip` to Chrome Web Store
3. Publish

### Migration on update

```js
chrome.runtime.onInstalled.addListener(async (details) => {
  if (details.reason === 'install') {
    // First install — set defaults
    await chrome.storage.local.set({
      settings: { theme: 'light', fontSize: 12 },
      dataVersion: 1,
    });
  }

  if (details.reason === 'update') {
    const { dataVersion = 0 } = await chrome.storage.local.get('dataVersion');

    // Run migrations sequentially
    if (dataVersion < 1) {
      await migrateV0toV1();
    }
    if (dataVersion < 2) {
      await migrateV1toV2();
    }

    await chrome.storage.local.set({ dataVersion: 2 });
    console.log(`Migrated from v${details.previousVersion} to ${chrome.runtime.getManifest().version}`);
  }
});
```

### Version numbering

```
MAJOR.MINOR.PATCH
1.0.0  → Initial release
1.1.0  → New feature added
1.1.1  → Bug fix
2.0.0  → Breaking changes / major redesign
```

---

## Performance Monitoring

### Service Worker Performance

```js
// Track SW startup time
const swStart = performance.now();
chrome.runtime.onInstalled.addListener(() => {
  console.log(`[Perf] SW ready in ${(performance.now() - swStart).toFixed(1)}ms`);
});

// Monitor alarm execution time
chrome.alarms.onAlarm.addListener(async (alarm) => {
  const start = performance.now();
  await handleAlarm(alarm);
  const duration = performance.now() - start;
  if (duration > 1000) {
    console.warn(`[Perf] Alarm ${alarm.name} took ${duration.toFixed(0)}ms`);
  }
});
```

### Storage Usage

```js
// Check storage usage
const usage = await chrome.storage.local.getBytesInUse(null);
console.log(`Storage used: ${(usage / 1024).toFixed(1)} KB of ~10 MB`);
```

### Content Script Impact

Minimize content script footprint:
- Defer heavy operations with `requestIdleCallback`
- Use `MutationObserver` instead of polling for DOM changes
- Disconnect observers when no longer needed
- Avoid injecting large CSS that triggers layout recalculation
