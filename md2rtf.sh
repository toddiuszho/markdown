#!/usr/bin/env bash
# md2rtf — Convert Markdown to RTF (or HTML) with pandoc-email.css styling.
#
# Two-stage pipeline: MD → standalone HTML (with CSS) → RTF.
# Portable: no macOS dependencies, no clipboard. Runs on Linux and macOS.
#
# Usage:
#   md2rtf file.md              # produces file.rtf
#   md2rtf --html file.md       # produces file.html
#   md2rtf -o out.rtf file.md   # explicit output path
#   cat file.md | md2rtf        # RTF to stdout
#   cat file.md | md2rtf --html # HTML to stdout
#
# Requires: pandoc (apt-get install pandoc / brew install pandoc)

set -euo pipefail

# ── Usage ────────────────────────────────────────────────────────────
usage() {
  cat >&2 <<'USAGE'
Usage: md2rtf [OPTIONS] [FILE.md]
       cat FILE.md | md2rtf [OPTIONS]

Convert Markdown to RTF with styled formatting.

Options:
  --html          Output HTML instead of RTF (styled, standalone)
  -o, --output F  Write output to file F (default: derive from input name)
  -h, --help      Show this help

Examples:
  md2rtf README.md              # produces README.rtf
  md2rtf --html README.md       # produces README.html
  md2rtf -o out.rtf README.md   # produces out.rtf
  cat notes.md | md2rtf         # RTF to stdout
  cat notes.md | md2rtf --html  # HTML to stdout
USAGE
  exit 1
}

# ── Argument parsing ─────────────────────────────────────────────────
OUTPUT_FORMAT="rtf"
OUTPUT_FILE=""
INPUT_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --html)
      OUTPUT_FORMAT="html"; shift ;;
    -o|--output)
      [ $# -lt 2 ] && { echo "Error: $1 requires an argument" >&2; exit 1; }
      OUTPUT_FILE="$2"; shift 2 ;;
    -h|--help)
      usage ;;
    -*)
      echo "Unknown option: $1" >&2; exit 1 ;;
    *)
      if [ -z "$INPUT_FILE" ]; then
        INPUT_FILE="$1"
      else
        echo "Error: unexpected argument: $1" >&2; exit 1
      fi
      shift ;;
  esac
done

# ── Dependency check ─────────────────────────────────────────────────
if ! command -v pandoc &>/dev/null; then
  echo "Error: pandoc not found. Install with: apt-get install pandoc (or brew install pandoc)" >&2
  exit 1
fi

# ── Resolve the CSS file bundled next to this script ─────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSS_FILE="${SCRIPT_DIR}/pandoc-email.css"

if [ ! -f "$CSS_FILE" ]; then
  echo "Error: pandoc-email.css not found at ${CSS_FILE}" >&2
  exit 1
fi

# ── Build pandoc args for stage 1 (MD → HTML) ───────────────────────
PANDOC_HTML_ARGS=(-f markdown -t html -s --syntax-highlighting=pygments -H "$CSS_FILE")

# ── Conversion function ─────────────────────────────────────────────
convert() {
  if [ "$OUTPUT_FORMAT" = "html" ]; then
    pandoc "${PANDOC_HTML_ARGS[@]}" "$@"
  else
    pandoc "${PANDOC_HTML_ARGS[@]}" "$@" | pandoc -f html -t rtf -s
  fi
}

# ── Derive output filename if needed ────────────────────────────────
if [ -z "$OUTPUT_FILE" ] && [ -n "$INPUT_FILE" ]; then
  BASENAME="${INPUT_FILE%.md}"
  BASENAME="${BASENAME%.markdown}"
  OUTPUT_FILE="${BASENAME}.${OUTPUT_FORMAT}"
fi

# ── Run ──────────────────────────────────────────────────────────────
if [ -n "$INPUT_FILE" ]; then
  if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: file not found: $INPUT_FILE" >&2
    exit 1
  fi
  if [ -n "$OUTPUT_FILE" ]; then
    convert "$INPUT_FILE" > "$OUTPUT_FILE"
    echo "Wrote ${OUTPUT_FILE}" >&2
  else
    convert "$INPUT_FILE"
  fi
elif [ ! -t 0 ]; then
  # Stdin mode (piped input)
  if [ -n "$OUTPUT_FILE" ]; then
    convert > "$OUTPUT_FILE"
    echo "Wrote ${OUTPUT_FILE}" >&2
  else
    convert
  fi
else
  usage
fi
