#!/usr/bin/env node
"use strict";

const { execFileSync, execSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");

// ── Built-in CSS ────────────────────────────────────────────────────
const DEFAULT_CSS = path.join(__dirname, "..", "assets", "pandoc-email.css");

// ── Usage ───────────────────────────────────────────────────────────
function usage() {
  const msg = `
Usage: markdown-convert [OPTIONS] [FILE.md]
       cat FILE.md | markdown-convert [OPTIONS]

Convert Markdown to styled RTF, HTML, or macOS clipboard rich text.

Formats:
  --rtf             Output RTF (default)
  --html            Output standalone styled HTML
  --copy            Copy rich text to macOS clipboard (pbcopy)

Input:
  FILE.md           Read from a Markdown file
  (stdin)           Pipe Markdown via stdin
  -p, --paste       Read Markdown from macOS clipboard (pbpaste)

Output:
  -o, --output F    Write output to file F
                    (default: derive from input filename, or stdout)

Styling:
  --css FILE        Use a custom CSS file instead of the built-in style

Other:
  -h, --help        Show this help
  -v, --version     Show version

Examples:
  markdown-convert README.md                # produces README.rtf
  markdown-convert --html README.md         # produces README.html
  markdown-convert --copy README.md          # copy rich text to clipboard
  markdown-convert -p --copy                # clipboard MD → clipboard rich text
  markdown-convert -o out.rtf README.md     # explicit output path
  cat notes.md | markdown-convert           # RTF to stdout
  cat notes.md | markdown-convert --html    # HTML to stdout
  markdown-convert --css my.css README.md   # custom styling
`.trim();
  process.stderr.write(msg + "\n");
  process.exit(1);
}

// ── Argument parsing ────────────────────────────────────────────────
let format = "rtf";
let outputFile = "";
let inputFile = "";
let cssFile = DEFAULT_CSS;
let copyMode = false;
let pasteMode = false;

const args = process.argv.slice(2);

for (let i = 0; i < args.length; i++) {
  switch (args[i]) {
    case "--rtf":
      format = "rtf";
      break;
    case "--html":
      format = "html";
      break;
    case "--copy":
      copyMode = true;
      break;
    case "-p":
    case "--paste":
      pasteMode = true;
      break;
    case "-o":
    case "--output":
      if (i + 1 >= args.length) {
        process.stderr.write("Error: " + args[i] + " requires an argument\n");
        process.exit(1);
      }
      outputFile = args[++i];
      break;
    case "--css":
      if (i + 1 >= args.length) {
        process.stderr.write("Error: --css requires an argument\n");
        process.exit(1);
      }
      cssFile = path.resolve(args[++i]);
      break;
    case "-h":
    case "--help":
      usage();
      break;
    case "-v":
    case "--version": {
      const pkg = require("../package.json");
      console.log(pkg.version);
      process.exit(0);
    }
    default:
      if (args[i].startsWith("-")) {
        process.stderr.write("Unknown option: " + args[i] + "\n");
        process.exit(1);
      }
      if (inputFile) {
        process.stderr.write("Error: unexpected argument: " + args[i] + "\n");
        process.exit(1);
      }
      inputFile = args[i];
  }
}

// ── Dependency checks ───────────────────────────────────────────────
try {
  execFileSync("pandoc", ["--version"], { stdio: "ignore" });
} catch {
  process.stderr.write(
    "Error: pandoc not found. Install with: brew install pandoc (or apt-get install pandoc)\n"
  );
  process.exit(1);
}

if (!fs.existsSync(cssFile)) {
  process.stderr.write("Error: CSS file not found: " + cssFile + "\n");
  process.exit(1);
}

if (copyMode && os.platform() !== "darwin") {
  process.stderr.write("Error: --copy requires macOS\n");
  process.exit(1);
}

if (pasteMode && os.platform() !== "darwin") {
  process.stderr.write("Error: --paste requires macOS\n");
  process.exit(1);
}

// ── Read input ──────────────────────────────────────────────────────
let markdown;

if (pasteMode) {
  markdown = execFileSync("pbpaste", { encoding: "utf8" });
} else if (inputFile) {
  if (!fs.existsSync(inputFile)) {
    process.stderr.write("Error: file not found: " + inputFile + "\n");
    process.exit(1);
  }
  markdown = fs.readFileSync(inputFile, "utf8");
} else if (!process.stdin.isTTY) {
  markdown = fs.readFileSync(0, "utf8"); // fd 0 = stdin
} else {
  usage();
}

// ── Pandoc: MD → styled HTML ────────────────────────────────────────
const pandocHtmlArgs = [
  "-f", "markdown",
  "-t", "html",
  "-s",
  "--syntax-highlighting=pygments",
  "-H", cssFile,
];

const html = execFileSync("pandoc", pandocHtmlArgs, {
  input: markdown,
  encoding: "utf8",
  maxBuffer: 50 * 1024 * 1024,
});

// ── Convert to final format ─────────────────────────────────────────
let output;

if (copyMode) {
  // macOS clipboard: hex-encode HTML, set via osascript
  const hex = Buffer.from(html, "utf8")
    .toString("hex");
  execFileSync("osascript", ["-e", `set the clipboard to «data HTML${hex}»`]);
  process.stderr.write("Copied to clipboard as rich text.\n");
  process.exit(0);
} else if (format === "html") {
  output = html;
} else {
  // HTML → RTF via pandoc second stage
  output = execFileSync("pandoc", ["-f", "html", "-t", "rtf", "-s"], {
    input: html,
    encoding: "utf8",
    maxBuffer: 50 * 1024 * 1024,
  });
}

// ── Derive output filename if needed ────────────────────────────────
if (!outputFile && inputFile) {
  const ext = format === "html" ? ".html" : ".rtf";
  const base = inputFile.replace(/\.(md|markdown)$/i, "");
  outputFile = base + ext;
}

// ── Write output ────────────────────────────────────────────────────
if (outputFile) {
  fs.writeFileSync(outputFile, output);
  process.stderr.write("Wrote " + outputFile + "\n");
} else {
  process.stdout.write(output);
}
