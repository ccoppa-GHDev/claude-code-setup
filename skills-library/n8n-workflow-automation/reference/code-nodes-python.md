# Python Code Node Reference

Guide for writing Python in n8n Code nodes. **Use JavaScript for 95% of tasks** — Python is for when you specifically need Python logic.

---

## When to Use Python vs JavaScript

**Use Python when**:
- Complex regex/string processing where Python excels
- Statistical calculations using `statistics` module
- Data structures leveraging `collections` (Counter, defaultdict, namedtuple)
- Team prefers Python syntax

**Use JavaScript when** (95% of cases):
- `$helpers.httpRequest()` needed (Python has no HTTP client)
- Luxon DateTime needed (Python datetime is more verbose)
- `$jmespath()` JSON querying needed
- `$getWorkflowStaticData()` persistence needed
- Maximum compatibility and community examples

---

## Mode Selection

Same as JavaScript:
- **Run Once for All Items** (95%): Process all items, return list
- **Run Once for Each Item** (5%): Process one item, return single dict

---

## Data Access Patterns

**CRITICAL**: Python uses `_input` (underscore), not `$input` (dollar sign).

### All Items
```python
items = _input.all()
# Returns list of objects with .json property

result = []
for item in items:
    result.append({
        "json": {
            "id": item.json["id"],
            "name": item.json["name"].upper()
        }
    })
return result
```

### First Item
```python
first = _input.first()
config = first.json
return [{"json": {"value": config["setting"]}}]
```

### Current Item (Each Item mode)
```python
current = _input.item
return {"json": {"processed": current.json["name"]}}
```

### Webhook Data (CRITICAL — same .body gotcha)
```python
# ❌ WRONG
email = _input.first().json["email"]

# ✅ CORRECT — data under .body
email = _input.first().json["body"]["email"]
name = _input.first().json["body"]["name"]
```

### Safe Dictionary Access
```python
# Use .get() to avoid KeyError
name = item.json.get("name", "Unknown")
email = item.json.get("body", {}).get("email", "")
tags = item.json.get("tags", [])
```

---

## Return Format

**List of dicts with `"json"` key** (All Items mode):
```python
return [
    {"json": {"name": "Alice", "processed": True}},
    {"json": {"name": "Bob", "processed": True}}
]
```

**Single dict** (Each Item mode):
```python
return {"json": {"name": "Alice", "processed": True}}
```

---

## Available Standard Library

### Core Data Processing
```python
import json              # JSON encode/decode
import re                # Regular expressions
import math              # Math functions
import statistics        # mean, median, stdev
import collections       # Counter, defaultdict, OrderedDict, namedtuple
import itertools         # chain, groupby, combinations, permutations
import functools         # reduce, lru_cache, partial
import operator          # itemgetter, attrgetter
```

### String & Text
```python
import string            # Constants (ascii_letters, digits, punctuation)
import textwrap          # Text wrapping and dedenting
import csv               # CSV reading/writing (via io.StringIO)
import io                # StringIO, BytesIO for in-memory streams
```

### Date & Time
```python
import datetime          # Date, time, datetime, timedelta
import calendar          # Calendar functions
import time              # Time functions
```

### Encoding & Hashing
```python
import base64            # Base64 encode/decode
import hashlib           # MD5, SHA1, SHA256, etc.
import hmac              # HMAC authentication
import urllib.parse      # URL encode/decode
```

### Math & Numbers
```python
import decimal           # Precise decimal arithmetic
import fractions         # Rational numbers
import random            # Random number generation
```

### Data Structures
```python
import copy              # Deep/shallow copy
import dataclasses       # Data classes
import enum              # Enumerations
import typing            # Type hints
import uuid              # UUID generation
```

---

## Common Patterns

### Filter and Transform
```python
items = _input.all()
return [
    {"json": {
        "id": item.json["id"],
        "name": item.json["name"].strip().upper(),
        "amount": float(item.json.get("amount", 0))
    }}
    for item in items
    if item.json.get("status") == "active"
]
```

### Group By with Counter
```python
from collections import Counter, defaultdict

items = _input.all()
groups = defaultdict(list)

for item in items:
    groups[item.json["category"]].append(item.json)

return [
    {"json": {"category": k, "count": len(v), "items": v}}
    for k, v in groups.items()
]
```

### Regex Processing
```python
import re

items = _input.all()
pattern = re.compile(r'(\d{3})-(\d{3})-(\d{4})')

result = []
for item in items:
    text = item.json.get("phone", "")
    match = pattern.search(text)
    if match:
        result.append({"json": {
            "original": text,
            "formatted": f"({match.group(1)}) {match.group(2)}-{match.group(3)}"
        }})
return result if result else [{"json": {"message": "No matches found"}}]
```

### Statistical Analysis
```python
import statistics

items = _input.all()
values = [float(item.json["amount"]) for item in items if item.json.get("amount")]

return [{"json": {
    "count": len(values),
    "mean": round(statistics.mean(values), 2) if values else 0,
    "median": round(statistics.median(values), 2) if values else 0,
    "stdev": round(statistics.stdev(values), 2) if len(values) > 1 else 0,
    "min": min(values) if values else 0,
    "max": max(values) if values else 0
}}]
```

### Date Processing
```python
from datetime import datetime, timedelta

items = _input.all()
now = datetime.utcnow()

return [
    {"json": {
        "id": item.json["id"],
        "created": item.json["created_at"],
        "age_days": (now - datetime.fromisoformat(
            item.json["created_at"].replace("Z", "+00:00")
        ).replace(tzinfo=None)).days,
        "is_recent": (now - datetime.fromisoformat(
            item.json["created_at"].replace("Z", "+00:00")
        ).replace(tzinfo=None)).days < 7
    }}
    for item in items
]
```

### CSV Processing (In-Memory)
```python
import csv
import io

csv_text = _input.first().json["body"]["csv_data"]
reader = csv.DictReader(io.StringIO(csv_text))

return [{"json": dict(row)} for row in reader]
```

---

## Top 5 Errors and Fixes

### 1. ModuleNotFoundError (Most Common!)
```python
# ❌ These DO NOT EXIST in n8n Python
import requests      # No HTTP library
import pandas        # No data analysis
import numpy         # No numerical computing
import bs4           # No web scraping

# ✅ Use standard library alternatives
import urllib.request  # Basic URL fetching (limited)
import json           # JSON processing
import csv            # CSV processing
import statistics     # Statistical functions
```

### 2. KeyError
```python
# ❌ Crashes if key missing
value = item.json["nonexistent"]

# ✅ Use .get() with default
value = item.json.get("nonexistent", "default")
```

### 3. IndexError
```python
# ❌ Crashes if list empty
first = items[0]

# ✅ Check length first
first = items[0] if items else None
```

### 4. Wrong Return Format
```python
# ❌ Missing "json" key
return [{"name": "Alice"}]

# ✅ Correct format
return [{"json": {"name": "Alice"}}]
```

### 5. Using $input Instead of _input
```python
# ❌ Wrong prefix (JavaScript syntax)
items = $input.all()

# ✅ Python uses underscore
items = _input.all()
```

---

## Key Limitations Summary

| Feature | JavaScript | Python |
|---------|-----------|--------|
| HTTP requests | `$helpers.httpRequest()` ✅ | ❌ No library |
| Date/time | Luxon `DateTime` ✅ | `datetime` (verbose) |
| JSON querying | `$jmespath()` ✅ | ❌ Not available |
| Persistent storage | `$getWorkflowStaticData()` ✅ | ❌ Not available |
| External packages | ❌ None | ❌ None |
| Data access prefix | `$input` | `_input` |
| Standard library | Limited | Full Python stdlib |
