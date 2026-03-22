#!/usr/bin/env bash
# md2clip — Convert Markdown to styled rich text on the macOS clipboard.
#
# Uses the osascript HTML clipboard trick (credit: Andrew Heiss) combined
# with killercup's pandoc.css (public domain/CC0/MIT/Apache 2.0) for
# sensible typography out of the box. Bypasses textutil entirely.
#
# Usage:
#   md2clip file.md        # from a file
#   md2clip -p             # from clipboard (pbpaste → convert → replace clipboard)
#   cat file.md | md2clip  # from stdin (piped)
#   echo "# Hi" | md2clip  # from stdin (inline)
#
# Requires: pandoc (brew install pandoc)
# Ships with macOS: osascript, hexdump, pbpaste

set -euo pipefail

# ── Dependency check ─────────────────────────────────────────────────
if ! command -v pandoc &>/dev/null; then
  echo "Error: pandoc not found. Install with: brew install pandoc" >&2
  exit 1
fi

# ── Resolve the CSS file bundled next to this script ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSS_FILE="${SCRIPT_DIR}/pandoc-email.css"

if [ ! -f "$CSS_FILE" ]; then
  echo "Error: pandoc-email.css not found at ${CSS_FILE}" >&2
  exit 1
fi

# ── Build pandoc args ────────────────────────────────────────────────
# -s (standalone) is required so pandoc emits <head> where -H injects CSS.
# --highlight-style=pygments gives syntax-highlighted code blocks.
# PANDOC_ARGS=(-f markdown -t html -s --highlight-style=pygments -H "$CSS_FILE")
PANDOC_ARGS=(-f markdown -t html -s --syntax-highlighting=pygments -H "$CSS_FILE")

# ── Input handling ───────────────────────────────────────────────────
if [ $# -ge 1 ] && [ "$1" = "-p" ]; then
  # Clipboard mode: read markdown from clipboard, convert, replace clipboard
  HEX=$(pbpaste | pandoc "${PANDOC_ARGS[@]}" | hexdump -ve '1/1 "%.2x"')
elif [ $# -ge 1 ] && [ -f "$1" ]; then
  # File mode
  HEX=$(pandoc "${PANDOC_ARGS[@]}" "$1" | hexdump -ve '1/1 "%.2x"')
elif [ ! -t 0 ]; then
  # Stdin mode (piped input detected)
  HEX=$(pandoc "${PANDOC_ARGS[@]}" | hexdump -ve '1/1 "%.2x"')
else
  # No args, no pipe — show usage
  echo "Usage: md2clip <file.md>    # from file" >&2
  echo "       md2clip -p           # from clipboard" >&2
  echo "       cat file | md2clip   # from stdin" >&2
  exit 1
fi

# ── Place rendered HTML on clipboard via AppleScript ─────────────────
osascript -e "set the clipboard to «data HTML${HEX}»"

echo "Copied to clipboard as rich text."

