#!/usr/bin/env bash
#
# install.sh — Deploy Claude Code system config to ~/.claude/
#
# Syncs this repo's contents to the global ~/.claude/ directory.
# Safe to run repeatedly. Backs up existing CLAUDE.md before overwriting.
# Does NOT touch runtime files (settings.json, history.jsonl, projects/, etc.)
#

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$HOME/.claude"
BACKUP_DIR="$TARGET/backups"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  Claude Code System — install.sh     ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── Preflight checks ──────────────────────────────────────────────

[ -f "$REPO_DIR/deploy/CLAUDE.md" ] || error "deploy/CLAUDE.md not found. Run from the repo root."
[ -d "$REPO_DIR/commands" ]         || error "commands/ not found. Run from the repo root."
[ -d "$REPO_DIR/skills-library" ]   || error "skills-library/ not found. Run from the repo root."

# ── Create directory structure ────────────────────────────────────

echo "Creating directory structure..."
mkdir -p "$TARGET"/{commands,templates,agents-library/{reviewers,subagents},skills-library,mcp-catalog}
mkdir -p "$BACKUP_DIR"
info "Directory structure ready"

# ── Backup existing CLAUDE.md ─────────────────────────────────────

if [ -f "$TARGET/CLAUDE.md" ]; then
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    cp "$TARGET/CLAUDE.md" "$BACKUP_DIR/CLAUDE.md.$TIMESTAMP"
    info "Backed up existing CLAUDE.md → backups/CLAUDE.md.$TIMESTAMP"
fi

# ── Deploy CLAUDE.md ──────────────────────────────────────────────

cp "$REPO_DIR/deploy/CLAUDE.md" "$TARGET/CLAUDE.md"
info "CLAUDE.md deployed ($(wc -l < "$REPO_DIR/deploy/CLAUDE.md") lines)"

# ── Deploy commands ───────────────────────────────────────────────

COMMAND_COUNT=0
for f in "$REPO_DIR"/commands/*.md; do
    cp "$f" "$TARGET/commands/"
    COMMAND_COUNT=$((COMMAND_COUNT + 1))
done
info "Commands deployed ($COMMAND_COUNT files)"

# ── Deploy templates ──────────────────────────────────────────────

# Remove old single-template format if present
[ -f "$TARGET/templates/CLAUDE-template.md" ] && rm "$TARGET/templates/CLAUDE-template.md" && warn "Removed old CLAUDE-template.md (replaced by path-aware templates)"

cp "$REPO_DIR"/templates/*.md "$TARGET/templates/"
info "Templates deployed ($(ls "$REPO_DIR"/templates/*.md | wc -l | tr -d ' ') files)"

# ── Deploy agents ─────────────────────────────────────────────────

# Remove old flat agent files if present
OLD_AGENTS=("code-quality-reviewer.md" "code-reviewer.md" "documentation-accuracy-reviewer.md" "performance-reviewer.md" "security-code-reviewer.md" "test-specialist.md")
CLEANED=0
for old in "${OLD_AGENTS[@]}"; do
    if [ -f "$TARGET/agents-library/$old" ]; then
        rm "$TARGET/agents-library/$old"
        CLEANED=$((CLEANED + 1))
    fi
done
[ $CLEANED -gt 0 ] && warn "Removed $CLEANED old flat agent files (replaced by reviewers/subagents structure)"

cp "$REPO_DIR/agents-library/README.md" "$TARGET/agents-library/"
cp "$REPO_DIR"/agents-library/reviewers/*.md "$TARGET/agents-library/reviewers/"
cp "$REPO_DIR"/agents-library/subagents/*.md "$TARGET/agents-library/subagents/"

REVIEWER_COUNT=$(ls "$REPO_DIR"/agents-library/reviewers/*.md | wc -l | tr -d ' ')
SUBAGENT_COUNT=$(ls "$REPO_DIR"/agents-library/subagents/*.md | wc -l | tr -d ' ')
info "Agents deployed ($REVIEWER_COUNT reviewers + $SUBAGENT_COUNT subagents)"

# ── Deploy skills library ────────────────────────────────────────

# Copy SKILLS-INDEX.md
cp "$REPO_DIR/skills-library/SKILLS-INDEX.md" "$TARGET/skills-library/"

# Copy all skill folders (rsync for efficiency, cp -r as fallback)
SKILL_COUNT=0
for skill_dir in "$REPO_DIR"/skills-library/*/; do
    skill_name=$(basename "$skill_dir")
    cp -r "$skill_dir" "$TARGET/skills-library/"
    SKILL_COUNT=$((SKILL_COUNT + 1))
done
info "Skills deployed ($SKILL_COUNT skills + SKILLS-INDEX.md)"

# ── Deploy MCP catalog ───────────────────────────────────────────

cp "$REPO_DIR/mcp-catalog/MCP-Servers.md" "$TARGET/mcp-catalog/"
info "MCP catalog deployed"

# ── Deploy hooks config ──────────────────────────────────────────

cp "$REPO_DIR/begin-config.json" "$TARGET/begin-config.json"
info "Hooks config deployed"

# ── Summary ───────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════╗"
echo "║  Deploy complete                     ║"
echo "╚══════════════════════════════════════╝"
echo ""
echo "  CLAUDE.md      39 lines"
echo "  Commands       $COMMAND_COUNT"
echo "  Templates      $(ls "$TARGET"/templates/*.md | wc -l | tr -d ' ')"
echo "  Agents         $REVIEWER_COUNT reviewers + $SUBAGENT_COUNT subagents"
echo "  Skills         $SKILL_COUNT"
echo "  MCP catalog    ✓"
echo "  Hooks config   ✓"
echo ""
echo "Run 'claude' and type /begin to initialize a project."
