# Security Reference

Security is the primary reason extensions get rejected from the Chrome Web Store and the primary vector for user harm. Apply these patterns in all extension code.

## Table of Contents
- [Content Security Policy (CSP)](#content-security-policy)
- [Permissions Strategy](#permissions-strategy)
- [XSS Prevention](#xss-prevention)
- [Secure Messaging](#secure-messaging)
- [Data Handling & Encryption](#data-handling--encryption)
- [web_accessible_resources Hardening](#web_accessible_resources-hardening)
- [Cross-Origin Requests](#cross-origin-requests)
- [Common Vulnerabilities](#common-vulnerabilities)

---

## Content Security Policy

### MV3 Default CSP (extension pages)

```
script-src 'self'; object-src 'self'
```

**This means:**
- Only scripts bundled in the extension package can execute
- No inline `<script>` tags in HTML — all JS must be in separate `.js` files
- No `eval()`, `new Function()`, `setTimeout('string')`, `setInterval('string')`
- No loading scripts from CDNs or remote servers
- No inline event handlers like `onclick="..."` in HTML

### CSP for sandbox pages

Sandbox pages have a relaxed CSP that allows `eval()` but cannot access chrome.* APIs:

```json
{
  "sandbox": {
    "pages": ["sandbox/sandbox.html"]
  },
  "content_security_policy": {
    "sandbox": "sandbox allow-scripts; script-src 'self' 'unsafe-eval'; object-src 'self'"
  }
}
```

Use sandboxed pages for template engines or libraries requiring `eval()`. Communicate via `window.postMessage`.

### Content script CSP

Content scripts run in an isolated world but are subject to the **page's** CSP for any DOM elements they create. Avoid injecting inline scripts into the page. Instead:

```js
// ❌ WRONG — blocked by page's CSP
const script = document.createElement('script');
script.textContent = 'console.log("injected")';
document.head.appendChild(script);

// ✅ CORRECT — inject from extension bundle
const script = document.createElement('script');
script.src = chrome.runtime.getURL('inject/page-script.js');
document.head.appendChild(script);
```

---

## Permissions Strategy

### Principle of Least Privilege

**Tier 1: No permissions needed**
- `chrome.runtime` (messaging, getURL)
- `chrome.i18n`
- Content script matching (declared in manifest)

**Tier 2: Low-risk permissions (no install warning)**
- `storage` — Extension storage
- `alarms` — Scheduled tasks
- `contextMenus` — Right-click menus
- `offscreen` — Offscreen documents
- `sidePanel` — Side panel UI

**Tier 3: Medium-risk permissions (shows install warning)**
- `activeTab` — Access current tab on user gesture (preferred over `tabs`)
- `scripting` — Programmatic script injection
- `notifications` — System notifications
- `cookies` — Cookie access (with host_permissions)

**Tier 4: High-risk permissions (strong warning, more review scrutiny)**
- `tabs` — Read all tab URLs and titles
- `webNavigation` — Observe navigation events
- `webRequest` — Observe network requests
- `declarativeNetRequest` — Modify network requests
- `<all_urls>` host permission — Access all sites
- `clipboardRead` / `clipboardWrite`
- `downloads` — Manage downloads

### Use Optional Permissions

Request permissions at runtime when needed, not at install:

```json
{
  "permissions": ["storage", "alarms"],
  "optional_permissions": ["tabs", "notifications"],
  "optional_host_permissions": ["https://api.example.com/*"]
}
```

```js
// Request when needed (must be triggered by user gesture)
document.getElementById('enable-notifications').addEventListener('click', async () => {
  const granted = await chrome.permissions.request({
    permissions: ['notifications'],
  });

  if (granted) {
    initNotifications();
  }
});

// Check if granted
const hasPermission = await chrome.permissions.contains({
  permissions: ['notifications'],
});

// Remove when no longer needed
await chrome.permissions.remove({ permissions: ['notifications'] });
```

### activeTab vs tabs

| Feature | `activeTab` | `tabs` |
|---|---|---|
| Access scope | Current tab on click | All tabs always |
| Install warning | Minimal | "Read your browsing history" |
| When to use | User-initiated actions | Background tab monitoring |
| URL access | Only active tab, on gesture | All tab URLs |

**Always prefer `activeTab`** unless you genuinely need to enumerate/monitor all tabs.

---

## XSS Prevention

### Never use innerHTML with untrusted data

```js
// ❌ DANGEROUS — XSS vector
element.innerHTML = userProvidedContent;

// ✅ SAFE — text only
element.textContent = userProvidedContent;

// ✅ SAFE — structured DOM creation
const link = document.createElement('a');
link.href = sanitizeURL(userURL);
link.textContent = userText;
container.appendChild(link);
```

### Sanitize URLs

```js
function sanitizeURL(url) {
  try {
    const parsed = new URL(url);
    if (!['http:', 'https:'].includes(parsed.protocol)) {
      return '#';
    }
    return parsed.href;
  } catch {
    return '#';
  }
}

// ❌ NEVER trust user input as URL directly
chrome.tabs.create({ url: userInput });

// ✅ Validate first
const safeURL = sanitizeURL(userInput);
if (safeURL !== '#') {
  chrome.tabs.create({ url: safeURL });
}
```

### Template rendering

If you must render dynamic HTML, use a DOM-based approach:

```js
function createListItem(item) {
  const li = document.createElement('li');
  const title = document.createElement('strong');
  title.textContent = item.title;
  const desc = document.createElement('p');
  desc.textContent = item.description;
  li.append(title, desc);
  return li;
}

// Batch render
const fragment = document.createDocumentFragment();
items.forEach((item) => fragment.appendChild(createListItem(item)));
container.appendChild(fragment);
```

---

## Secure Messaging

### Validate message types

```js
// background.js — validate all incoming messages
const VALID_TYPES = new Set(['GET_DATA', 'SAVE_DATA', 'GET_SETTINGS']);

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  // Validate message structure
  if (!message || typeof message.type !== 'string' || !VALID_TYPES.has(message.type)) {
    console.warn('Invalid message received:', message);
    return;
  }

  // Validate sender
  if (sender.id !== chrome.runtime.id) {
    console.warn('Message from unknown extension:', sender.id);
    return;
  }

  handleMessage(message, sender).then(sendResponse);
  return true;
});
```

### Content script ↔ page isolation

Content scripts share the DOM but NOT the JS context. If you need to communicate with page scripts:

```js
// Content script — listen for page messages
window.addEventListener('message', (event) => {
  if (event.source !== window) return;
  if (event.data?.source !== 'MY_EXTENSION_PAGE') return;

  // Validate and forward to background
  chrome.runtime.sendMessage({
    type: 'PAGE_DATA',
    payload: sanitize(event.data.payload),
  });
});

// Page script (injected via web_accessible_resources)
window.postMessage({ source: 'MY_EXTENSION_PAGE', payload: data }, '*');
```

---

## Data Handling & Encryption

### Sensitive data storage

For API keys, tokens, or sensitive user data — use `chrome.storage.session` (cleared on browser restart) or encrypt before storing:

```js
// Simple encryption using Web Crypto API
async function deriveKey(password, salt) {
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveKey']
  );
  return crypto.subtle.deriveKey(
    { name: 'PBKDF2', salt, iterations: 100000, hash: 'SHA-256' },
    keyMaterial,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt']
  );
}

async function encryptData(data, password) {
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const key = await deriveKey(password, salt);
  const encrypted = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    new TextEncoder().encode(JSON.stringify(data))
  );
  return { salt: [...salt], iv: [...iv], data: [...new Uint8Array(encrypted)] };
}

async function decryptData(encrypted, password) {
  const key = await deriveKey(password, new Uint8Array(encrypted.salt));
  const decrypted = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: new Uint8Array(encrypted.iv) },
    key,
    new Uint8Array(encrypted.data)
  );
  return JSON.parse(new TextDecoder().decode(decrypted));
}
```

### Never log sensitive data

```js
// ❌ WRONG
console.log('User token:', token);
console.log('API response:', JSON.stringify(response));

// ✅ CORRECT
console.log('Token received:', token ? 'yes' : 'no');
console.log('API response status:', response.status);
```

---

## web_accessible_resources Hardening

Resources listed here are accessible to ANY web page matching the pattern. Minimize exposure:

```json
{
  "web_accessible_resources": [
    {
      "resources": ["inject/page-script.js", "icons/logo.svg"],
      "matches": ["https://specific-site.com/*"],
      "use_dynamic_url": true
    }
  ]
}
```

**`use_dynamic_url: true`**: Generates a unique URL per session, preventing fingerprinting of the extension.

**Never expose:**
- Configuration files
- API endpoints or keys
- Internal extension pages
- More resources than needed

---

## Cross-Origin Requests

Service workers and extension pages can make cross-origin requests if `host_permissions` are declared:

```json
{
  "host_permissions": ["https://api.example.com/*"]
}
```

```js
// Service worker — no CORS restrictions with host_permissions
const response = await fetch('https://api.example.com/data', {
  headers: { 'Authorization': `Bearer ${token}` },
});
```

**Content scripts** follow the page's CORS policy. Route cross-origin requests through the service worker:

```js
// content.js — ask background to fetch
const data = await chrome.runtime.sendMessage({
  type: 'FETCH',
  url: 'https://api.example.com/data',
});

// background.js — perform the fetch
chrome.runtime.onMessage.addListener((msg, sender, sendResponse) => {
  if (msg.type === 'FETCH') {
    fetch(msg.url).then(r => r.json()).then(sendResponse);
    return true;
  }
});
```

---

## Common Vulnerabilities

| Vulnerability | Vector | Prevention |
|---|---|---|
| XSS via innerHTML | User/page data rendered as HTML | Use `textContent`, DOM APIs |
| Privilege escalation | Content script sends unrestricted commands to background | Validate message types with allowlist |
| Data exfiltration | Overly broad `host_permissions` | Minimize permissions, use optional |
| Extension fingerprinting | Predictable `web_accessible_resources` URLs | Use `use_dynamic_url: true` |
| Prototype pollution | Merging untrusted objects with `Object.assign` | Validate input shape, use `structuredClone` |
| Open redirect | `chrome.tabs.create({ url: untrustedInput })` | Validate URL protocol (http/https only) |
| Storage injection | Storing unsanitized data, rendering later | Sanitize on write AND on render |
