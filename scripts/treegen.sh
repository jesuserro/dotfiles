#!/usr/bin/env bash
# Generate STRUCTURE.md with tree output (excludes build artifacts, deps, etc.)
# Usage: treegen.sh [DIR]
#   DIR  Target directory (default: current directory)
# When run from a repo root (e.g. via git pre-commit), runs in current dir and optionally runs git add.

set -e

# Same exclusions as VS Code "files.exclude" style
TREE_IGNORE='node_modules|dist|build|out|\.git|\.venv|venv|env|\.env|target|bin|obj|\.vs|\.idea|__pycache__|*.pyc|*.log|*.tmp|*.cache|\.ruff_cache|uncommitted|index_*|chunks|wal'

TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
ROOT_NAME="$(basename "$TARGET_DIR")"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"

if ! command -v tree &>/dev/null; then
  echo "treegen.sh: 'tree' not found. Install it (e.g. apt install tree / brew install tree)." >&2
  exit 1
fi

OUTPUT="$TARGET_DIR/STRUCTURE.md"
TREE_OUT="$(cd "$TARGET_DIR" && tree -a -I "$TREE_IGNORE" --dirsfirst -n --noreport . 2>/dev/null)" || true

{
  echo "# File Tree: $ROOT_NAME"
  echo ""
  echo "**Generated:** $DATE"
  echo "**Root Path:** \`$TARGET_DIR\`"
  echo ""
  echo "\`\`\`"
  echo "$TREE_OUT"
  echo "\`\`\`"
} > "$OUTPUT"

if git -C "$TARGET_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  git -C "$TARGET_DIR" add STRUCTURE.md
fi

echo "Written: $OUTPUT"
