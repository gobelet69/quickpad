# QuickPad

<p align="center">
  <img src="Resources/AppIcon.icns" alt="QuickPad Icon" width="128">
</p>

<p align="center">
  <b>An ultra-fast, native macOS text editor with intelligent live previews and low resource overhead.</b><br>
  Engineered with Swift 6 and AppKit specifically for Apple Silicon. Zero startup latency, zero telemetry.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/status-development%20%2F%20staging-amber" alt="Status: Staging">
  <img src="https://img.shields.io/badge/platform-macOS%2013.0%2B-blue?logo=apple" alt="macOS 13+">
  <img src="https://img.shields.io/badge/architecture-Apple%20Silicon%20(arm64)-purple" alt="Apple Silicon">
  <img src="https://img.shields.io/badge/language-Swift%206-orange?logo=swift" alt="Swift 6">
  <img src="https://img.shields.io/badge/ui-Native%20AppKit-black" alt="AppKit">
  <img src="https://img.shields.io/badge/tests-53%20assertions%20passing-brightgreen" alt="53 assertions passing">
  <img src="https://img.shields.io/badge/licence-MIT-green" alt="Licence MIT">
</p>

---

## 1. Overview

**QuickPad** is designed as the high-performance macOS counterpart to classic desktop text editors, engineered natively for Apple Silicon Macs using **Swift 6 and AppKit**. It pairs instant sub-100 ms cold launches and an ~8 MB baseline memory footprint with intelligent live inspectors for structured formats (GitHub Flavored Markdown, JSON trees, RFC 4180 CSV tables, XML, YAML, and sandboxed HTML).

It strictly prioritises:
$$\text{Performance} > \text{Reliability} > \text{Simplicity} > \text{Usability} > \text{Visual Polish}$$

---

## 2. Application Visuals & Previews

*Visual QA assets are catalogued during local verification builds.*

- **Interactive Split View**: Real-time side-by-side editing with live Markdown preview or virtualised JSON tree.
- **Line Number Gutter**: Custom flipped AppKit canvas with active line highlight and non-blocking layout calculations.
- **Theme**: Pure macOS Liquid Glass canvas following the 111iridescence Obsidian Ink (`#16101D`) and Pearl Canvas (`#FAF9FC`) design tokens.

---

## 3. Main Features

- **Instantaneous Startup & Minimal Footprint**: Cold launch in under 100 ms; baseline RSS memory footprint under 9 MB; 0.0% CPU usage while idle with no background daemon workers.
- **Intelligent Structured Previews**:
  - *GitHub Flavored Markdown*: Live preview supporting tables, task checkboxes (`- [x]`), fenced code blocks, and blockquotes inside a sandboxed, script-restricted `WKWebView`.
  - *JSON Tree Inspector*: Interactive hierarchical tree (`NSOutlineView`) with instant key filtering, "Copy Value", "Copy JSON Path", and formatting utilities.
  - *RFC 4180 CSV Grid*: Virtualised data table handling quoted fields, commas, tabs, escaped quotes, and multiline cells across datasets exceeding 100,000 rows.
  - *XML / YAML / TOML Diagnostics*: Structural tree inspectors with parse error highlighting.
- **Universal Text Integrity**:
  - Multi-stage encoding detection supporting UTF-8, UTF-16 LE, UTF-16 BE, Windows-1252, ISO-8859-1, MacRoman, and Shift-JIS.
  - Binary file detection heuristics to protect against accidental corruption of compiled binaries or image data.
  - Automatic detection and preservation of Unix (`\n`), Windows (`\r\n`), and legacy Mac (`\r`) line endings.
- **Crash-Resilient Atomic Writes**: Writes documents to a staging file before atomically replacing the destination, eliminating file corruption risks during power interruptions.
- **External Modification Tracking**: Monitors disk modification timestamps and alerts you if a file is modified externally by git or another process.

---

## 4. Measured Performance Benchmarks

*All benchmarks measured on Apple Silicon macOS 14+ (arm64, Release `-O` build).*

| Workload | Input Size | Processing Time | Memory RSS | Details |
| :--- | :--- | :--- | :--- | :--- |
| **Baseline Footprint** | N/A | **Instant** | **8.17 MB** | Raw process startup, zero background workers |
| **Plain Text Open** | 1 KB | **0.64 ms** | 53.7 MB | Instant buffer allocation and BOM verification |
| **Markdown Open** | 100 KB | **0.56 ms** | 53.7 MB | Direct text storage ingestion |
| **JSON Open** | 1 MB | **0.80 ms** | 53.9 MB | Text buffer ready for typing |
| **CSV Open** | 10 MB | **3.85 ms** | 63.6 MB | 114,000+ lines ingested in under 4 milliseconds |
| **Large Plain Text** | 50 MB | **28.55 ms** | 159.5 MB | Non-blocking streaming load |
| **Massive Plain Text** | 100 MB | **49.25 ms** | 347.3 MB | Sub-50 ms opening of 100 MB files |
| **GFM Markdown Parser** | 100 KB | **57.68 ms** | — | 1,000 sections, tables, code blocks |
| **JSON Tree Inspector** | 1 MB | **55.18 ms** | — | 10,000 nodes parsed into virtual tree |
| **CSV Table Parser** | 10 MB | **303.82 ms** | — | RFC 4180 parsing of 113,975 rows × 6 columns |
| **Safe Atomic Write** | 100 KB | **6.40 ms** | — | Crash-resilient atomic file write |

---

## 5. System Requirements

- **Operating System**: macOS 13.0 (Ventura) or newer (macOS 14 Sonoma and macOS 15+ fully supported).
- **Architecture**: Universal 2 binary natively supporting both **Apple Silicon** (`arm64`) and **Intel** (`x86_64`).
- **RAM**: Under 10 MB base memory footprint.
- **Disk Space**: ~5 MB for installation.
- **Privileges**: Standard user account. QuickPad does not require administrator privileges or root access.
- **Sandboxing**: Runs as a standard macOS user-space application (non-sandboxed) to allow opening and atomic-saving files across arbitrary user-specified directories, external drives, and developer paths without sandbox containment barriers.

---

## 6. Installation Instructions

1. Download the latest Universal DMG from the **[GitHub Releases](https://github.com/gobelet69/quickpad/releases/latest)** page:
   - `QuickPad-1.0.1-universal.dmg`
2. Open the downloaded `.dmg` disk image.
3. Drag **QuickPad.app** into your `/Applications` directory.
4. Launch **QuickPad** from Spotlight or `/Applications`.
5. **macOS Gatekeeper Verification (Non-Notarised Builds)**:
   Because releases are ad-hoc signed without an Apple Developer ID subscription, macOS Gatekeeper may present a dialog on first launch (*"QuickPad cannot be opened because Apple cannot check it for malicious software"*). To safely open the application:
   - **Via Finder**: Right-click (or Control-click) **QuickPad.app** in `/Applications`, choose **Open**, and click **Open** in the confirmation alert. Alternatively, navigate to **System Settings → Privacy & Security** and click **Open Anyway**.
   - **Via Terminal** (optional): Clear the quarantine extended attribute:
     ```bash
     xattr -d com.apple.quarantine "/Applications/QuickPad.app"
     ```
   Once opened, macOS permanently remembers your choice, and subsequent launches start instantly without warnings.

---

## 7. Getting Started

1. **Launch QuickPad**: Launches in under 100 ms with a clean blank document tab.
2. **Open Existing Files**: Press `Cmd + O` or drag files onto the editor. QuickPad automatically detects character encoding and line endings.
3. **Toggle Live Previews**: For Markdown, JSON, or CSV files, press `Cmd + Shift + P` to toggle between Editor Only, Split View, and Preview Only.
4. **Inspect JSON / CSV**: When opening a `.json` file, switch to Split View to explore the collapsible node hierarchy or extract JSON paths for APIs.

---

## 8. Usage Instructions

### Working with Large Files
QuickPad streams files up to 100 MB into memory in under 50 ms. When viewing large logs or text dumps, word wrap can be toggled off (`Option + Cmd + W`) for optimal scrolling performance.

### Markdown Previews
The Markdown renderer supports standard GitHub Flavored Markdown syntax including task checkboxes, tables, blockquotes, and fenced code blocks. Previews update in real time with debounced background parsing.

### File Format Conversions & Formatting
- **Format JSON**: Press `Option + Cmd + F` to re-indent and prettify raw JSON buffers with two-space indentation.
- **Line Ending Conversion**: Click the line-ending indicator in the status bar to convert between LF (`\n`) and CRLF (`\r\n`).

---

## 9. Keyboard Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| `Cmd + N` | New Document Tab | Opens a blank document tab |
| `Cmd + O` | Open File… | Native file open dialogue |
| `Cmd + S` | Save | Saves active document atomically |
| `Cmd + Shift + S` | Save As… | Saves document to a chosen destination |
| `Cmd + W` | Close Tab | Closes active tab (prompts if unsaved) |
| `Cmd + F` | Find & Replace | Opens search and replace bar |
| `Cmd + G` | Find Next | Advances to next match |
| `Cmd + Shift + G` | Find Previous | Jumps to previous match |
| `Cmd + L` | Go to Line… | Quick jump panel to any line number |
| `Cmd + Shift + P` | Toggle Preview | Cycles between Source, Split, and Preview |
| `Option + Cmd + W` | Toggle Word Wrap | Toggles soft wrapping |
| `Option + Cmd + F` | Format Document | Formats structured documents (e.g. JSON) |
| `Cmd + +` / `Cmd + -` | Zoom In / Out | Adjusts editor font size |
| `Cmd + 0` | Reset Zoom | Resets editor font to standard 13 pt |

---

## 10. Building from Source

### Prerequisites
- macOS 13.0 or later.
- Xcode 15+ / Command Line Tools with Swift 6:
  ```bash
  xcode-select --install
  ```

### Build Steps

1. Compile the Release application bundle:
   ```bash
   ./build.sh release
   open "QuickPad.app"
   ```
2. Run the automated test suite:
   ```bash
   ./test.sh
   ```
   All 53 unit assertions verify encoding detection, BOM parsing, CSV compliance, and atomic safety.
3. Run performance benchmarks:
   ```bash
   ./run_benchmark.sh
   ```
4. Package the distributable `.dmg`:
   ```bash
   ./package_dmg.sh
   ```

---

## 11. Troubleshooting

- **File shows unexpected character substitution**:
  QuickPad automatically tests for UTF-8, Windows-1252, and MacRoman encodings. If a file was saved with an obscure legacy encoding, ensure it has a Byte Order Mark or standard UTF-8 encoding.
- **Large files (>100 MB) display slower syntax highlighting**:
  For files exceeding 50 MB, disable word wrap (`Option + Cmd + W`) and syntax highlighting in preferences to maximize scrolling throughput.

---

## 12. Download and Releases

- **Status**: Development & Staging.
- **Repository Remote**: To be configured upon GitHub publication approval.
- **Artifacts**: Local DMG packaged at `QuickPad-1.0.1-universal.dmg`.

---

## 13. Contributing

Contributions and feedback are appreciated. Please ensure all pull requests maintain the sub-100 ms startup invariant, pass the 53 automated test assertions (`./test.sh`), and adhere to AppKit native design principles.

---

## 14. Licence

This project is licensed under the **[MIT Licence](LICENSE)**.

---

## 15. Acknowledgements

- Built with Apple's native AppKit and WebKit technologies.
- Inspired by the timeless speed and utility of classic desktop text editors.
- Developed by **[111iridescence](https://111iridescence.org)** with AI-assisted software systems engineering.
