---
name: title-variants
description: Generate title variants for YouTube videos from outlier analysis. Use when user asks to create title variations, generate YouTube titles, or adapt video titles.
category: video-content
path: agentic
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
env_vars:
  - ANTHROPIC_API_KEY
triggers: manual
---

# Title Variant Generation

## Goal
Analyze top-performing video titles and generate variants adapted to your niche.

## Scripts
- `./scripts/generate_title_variants.py` - Generate variants
- `./scripts/update_sheet.py` - Update sheets

## Usage

```bash
# Mode A: Update existing sheet with variants
python3 ./scripts/generate_title_variants.py \
  --sheet-url "SHEET_URL" \
  --mode update

# Mode B: Create new sheet with variants
python3 ./scripts/generate_title_variants.py \
  --input .tmp/outliers.json \
  --mode create
```

## How It Works
1. Analyzes original title's hook, emotional trigger, structure
2. Adapts to your specific niche
3. Generates 3 meaningfully different variants
4. Keeps under 100 characters (YouTube best practice)

## Configuration
```python
USER_CHANNEL_NICHE = "[YOUR_CHANNEL_NICHE]"  # e.g., "AI agents, automation, agentic workflows"
```

## Output
Three title variants per input, stored in sheet columns:
- Title Variant 1
- Title Variant 2
- Title Variant 3
