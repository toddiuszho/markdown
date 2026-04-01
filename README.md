# @toddiuszho/markdown-convert

Convert Markdown to styled RTF, HTML, or macOS clipboard rich text via pandoc.

## Quick Start

```bash
# file → RTF (default)
npx @toddiuszho/markdown-convert README.md

# file → HTML
npx @toddiuszho/markdown-convert --html README.md

# file → macOS clipboard as rich text
npx @toddiuszho/markdown-convert --copy README.md

# pipe from stdin
cat notes.md | npx @toddiuszho/markdown-convert --html
```

## Prerequisites

[Pandoc](https://pandoc.org/) must be installed:

```bash
# macOS
brew install pandoc

# Debian / Ubuntu
sudo apt-get install pandoc
```

## Install

```bash
# run directly (no install needed)
npx @toddiuszho/markdown-convert [OPTIONS] [FILE.md]

# or install globally
npm install -g @toddiuszho/markdown-convert
markdown-convert [OPTIONS] [FILE.md]
```

## Usage

```
markdown-convert [OPTIONS] [FILE.md]
cat FILE.md | markdown-convert [OPTIONS]
```

### Formats

| Flag | Description |
|------|-------------|
| `--rtf` | Output RTF (default) |
| `--html` | Output standalone styled HTML |
| `--copy` | Copy rich text to macOS clipboard (pbcopy) |

### Input

| Flag | Description |
|------|-------------|
| `FILE.md` | Read from a Markdown file |
| *(stdin)* | Pipe Markdown via stdin |
| `-p`, `--paste` | Read Markdown from macOS clipboard (pbpaste) |

### Output

| Flag | Description |
|------|-------------|
| `-o`, `--output FILE` | Write to a specific file |
| *(default)* | Derive filename from input (e.g. `README.md` → `README.rtf`), or write to stdout |

### Styling

| Flag | Description |
|------|-------------|
| `--css FILE` | Use a custom CSS file instead of the built-in style |

The built-in style is designed for clean, readable email-friendly output. To override it, pass your own CSS file with `--css`.

### Other

| Flag | Description |
|------|-------------|
| `-h`, `--help` | Show help |
| `-v`, `--version` | Show version |

## Examples

```bash
# Markdown file to RTF file
markdown-convert README.md                  # → README.rtf

# Markdown file to HTML file
markdown-convert --html README.md           # → README.html

# Explicit output path
markdown-convert -o out.rtf README.md

# Copy styled rich text to macOS clipboard
markdown-convert --copy README.md

# Read Markdown from clipboard, copy rich text back
markdown-convert -p --copy

# Pipe from stdin to stdout
cat notes.md | markdown-convert             # RTF to stdout
cat notes.md | markdown-convert --html      # HTML to stdout

# Use custom CSS
markdown-convert --css my-style.css README.md
```

## Platform Notes

The `--copy` and `--paste` flags use macOS-specific tools (`pbcopy` via `osascript` and `pbpaste`) and are only available on macOS. All other functionality works on any platform where pandoc and Node.js are installed.

## License

MIT
