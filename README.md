# QuickPad

> **An ultra-fast, native macOS text editor with intelligent previews.**  
> Crafted by **[111iridescence](https://111iridescence.org)**.

[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue?logo=apple)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-Apple%20Silicon%20(arm64)-purple)](https://111iridescence.org)
[![License](https://img.shields.io/badge/License-MIT-emerald)](LICENSE)

---

## Overview

**QuickPad** is designed as the native macOS counterpart to classic high-performance text editors like Notepad++, but engineered specifically for Apple Silicon with modern AppKit, zero startup latency, and intelligent live previews for structured formats.

It prioritizes:
$$\text{Performance} > \text{Reliability} > \text{Simplicity} > \text{Usability} > \text{Visual Polish}$$

- **Instantaneous Startup**: Cold launch in under 100 ms.
- **Ultra-Low Memory Footprint**: ~8 MB baseline RSS memory; zero memory leaks.
- **Silent & Efficient**: 0.0% CPU usage when idle; no background indexing or persistent daemons.
- **Smart Previews**: Live Markdown (GFM), interactive JSON tree with path extraction, virtualized CSV grid, structured XML/YAML/TOML inspectors, and sandboxed HTML preview.
- **Universal Text Integrity**: Automatic BOM detection (UTF-8, UTF-16 LE, UTF-16 BE), legacy encoding fallback (Windows-1252, ISO-8859-1, MacRoman, Shift-JIS), and binary file safety heuristics.
- **Native macOS Craftsmanship**: Custom tabs, line number gutter, regex find/replace bar, jump-to-line panel, atomic writes, and external file modification monitoring.

---

## Measured Performance Benchmarks

*All benchmarks measured on Apple Silicon macOS 14+ (arm64, Release `-O` build).*

| Workload | Input Size | Processing Time | Memory RSS | Details |
| :--- | :--- | :--- | :--- | :--- |
| **Baseline Footprint** | N/A | **Instant** | **8.17 MB** | Raw process startup, zero background workers |
| **Plain Text Open** | 1 KB | **0.64 ms** | 53.7 MB | Instant buffer allocation & BOM verification |
| **Markdown Open** | 100 KB | **0.56 ms** | 53.7 MB | Direct text storage ingestion |
| **JSON Open** | 1 MB | **0.80 ms** | 53.9 MB | Text buffer ready for typing |
| **CSV Open** | 10 MB | **3.85 ms** | 63.6 MB | 114,000+ lines ingested in under 4 milliseconds |
| **Large Plain Text** | 50 MB | **28.55 ms** | 159.5 MB | Non-blocking streaming load |
| **Massive Plain Text** | 100 MB | **49.25 ms** | 347.3 MB | Sub-50ms opening of 100 MB files |
| **GFM Markdown Parser** | 100 KB | **57.68 ms** | — | 1,000 sections, tables, code blocks |
| **JSON Tree Inspector** | 1 MB | **55.18 ms** | — | 10,000 nodes parsed into virtual tree |
| **CSV Table Parser** | 10 MB | **303.82 ms** | — | RFC 4180 parsing of 113,975 rows × 6 columns |
| **Safe Atomic Write** | 100 KB | **6.40 ms** | — | Crash-resilient atomic file write |
| **Syntax Highlighting** | 1,000 lines | **74.91 ms** | — | Viewport-aware regex colorization (Swift) |

---

## Key Features

### 1. High-Performance Text Engine
- **TextKit AppKit Engine**: Built upon macOS native text architecture with custom text container and storage configuration for high-frequency keystroke throughput.
- **Viewport-Aware Syntax Highlighting**: Colorizes visible glyphs first; clamps parsing range for large files to guarantee steady 60 fps typing and scrolling.
- **Line Number Gutter**: Custom flipped `NSView` drawing line numbers with active line highlighting and dynamic digit-width calculation.
- **Smart Pairing & Indentation**: Automatic bracket, parenthesis, and quote pairing; auto-indentation matching previous line depth.
- **Word Wrap Toggle**: Instant switching between wrapped and unwrapped horizontal scrolling (`⌥⌘W`).

### 2. Intelligent Previews
- **Markdown Preview (`⌘⇧P`)**: Clean GitHub Flavored Markdown renderer supporting tables, task checkboxes (`- [x]`), inline code, fenced code blocks with language tags, blockquotes, and headings. Rendered inside a secure, sandboxed `WKWebView` with JavaScript disabled and debounce updating.
- **Interactive JSON Inspector**: Tree view (`NSOutlineView`) displaying types, keys, and values. Includes interactive node search/filtering, expand/collapse toggles, "Copy Value", "Copy JSON Path", and "Format JSON" actions.
- **RFC 4180 CSV Grid**: Virtualized `NSTableView` handling quoted fields, commas, tabs, escaped quotes (`""`), and embedded newlines.
- **Structured XML / YAML / TOML**: Structural hierarchy inspector with syntax error diagnostics.
- **HTML Preview**: Sandboxed preview view with script restrictions.

### 3. File Safety & Integrity
- **Encoding Detection**: Multi-stage detection pipeline:
  1. Byte Order Marks (UTF-8, UTF-16 LE, UTF-16 BE).
  2. Binary file protection (scans for null bytes and control codes).
  3. Strict UTF-8 validation.
  4. Heuristic fallback for legacy encodings (Windows-1252, ISO-8859-1, MacRoman, Shift-JIS).
- **Line Ending Preservation**: Detects and maintains LF (`\n`), CRLF (`\r\n`), and CR (`\r`) conventions.
- **Crash-Resilient Atomic Writes**: Writes to a temporary staging file before replacing destination to eliminate risk of corruption during system interruptions.
- **External Modification Tracking**: Watches file modification timestamps to alert the user if a file has changed on disk.

### 4. 111iridescence Atelier Design
- Obsidian Ink (`#16101D`) and Pearl Canvas (`#FAF9FC`) dynamic theme tokens.
- Custom tab bar with unsaved change indicators (`•`), tab close buttons, and tab addition.
- Compact status bar showing cursor position (`Ln X, Col Y`), selection character count, total line/character counts, encoding, line ending format, language syntax, and preview mode switcher (`Source | Split | Preview`).
- Prismatic App Icon rendered in high resolution up to 1024×1024 Retina.

---

## Keyboard Shortcuts

| Action | Shortcut | Description |
| :--- | :--- | :--- |
| **New Tab** | `⌘N` | Opens a new blank document tab |
| **Open File** | `⌘O` | Native file open dialog |
| **Save** | `⌘S` | Saves current document atomically |
| **Save As** | `⇧⌘S` | Saves document to a new file path |
| **Close Tab** | `⌘W` | Closes current tab (prompts if unsaved) |
| **Find & Replace** | `⌘F` | Toggles search and replace bar |
| **Find Next** | `⌘G` | Advances to next search match |
| **Find Previous** | `⇧⌘G` | Jumps to previous search match |
| **Go to Line** | `⌘L` | Quick jump panel to any line number |
| **Toggle Preview** | `⇧⌘P` | Cycles between Source, Split, and Preview |
| **Toggle Word Wrap**| `⌥⌘W` | Toggles text wrapping |
| **Format Document** | `⌥⌘F` | Formats structured documents (e.g. JSON) |
| **Zoom In / Out** | `⌘+` / `⌘-` | Increases or decreases editor font size |
| **Reset Zoom** | `⌘0` | Resets editor font to standard size (13 pt) |

---

## Build & Verification

### Prerequisites
- macOS 13.0 or higher
- Xcode 15+ / Command Line Tools with Swift 6+

### Build Release Application
```bash
./build.sh release
```
The compiled application bundle will be created at `QuickPad.app`.

### Run Automated Tests
```bash
./test.sh
```
Executes all unit test suites covering encoding detection, BOM handling, line endings, CSV RFC 4180 parsing, Markdown generation, and document safety.

### Run Performance Benchmarks
```bash
./run_benchmark.sh
```
Executes the comprehensive performance suite across files from 1 KB to 100 MB.

### Package Distribution DMG
```bash
./package_dmg.sh
```
Generates a verified, read-only compressed disk image: `QuickPad-1.0.0.dmg`.

---

## License

QuickPad is licensed under the [MIT License](LICENSE).  
Copyright © 2026 **111iridescence** ([111iridescence.org](https://111iridescence.org)). All rights reserved.
