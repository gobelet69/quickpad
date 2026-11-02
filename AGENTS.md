# QuickPad — Agent Instructions & Architectural Guidelines

## 1. Project Overview & Architecture

**QuickPad** is an ultra-fast, minimalist native macOS text editor and scratchpad:
- **Language & Runtime**: Swift 6.0, AppKit, WebKit.
- **Key Modules**:
  - `Sources/QuickPad/`: High-performance text buffer, encoding detection (UTF-8, UTF-16, ASCII, ISO-8859-1), BOM handling, line ending normalization (LF, CRLF, CR), atomic document saving, Markdown rendering with WebKit, and syntax highlighting.
  - `Tests/QuickPadTests/`: Test runner exercising encoding, line ending, CSV/TSV, JSON path extraction, Markdown parsing, and atomic document writes.
- **Brand Identity**: Ultraviolet (`#8A38F5` Light / `#A855F7` Dark) with Subtle Magenta.

---

## 2. Invariants & Safety Rules

1. **Atomic File Safety**:
   - Saving documents must always use atomic writes (`.atomic`) to prevent corruption during unexpected shutdowns or write interruptions.
2. **Deterministic Encoding Detection**:
   - Preserve user file encodings accurately without lossy fallback.
3. **iCloud & Build Paths**:
   - The test script `./test.sh` compiles tests to `/tmp/QuickPadTestsRunner`.
   - Release builds via `./build.sh release` produce the universal application bundle.
4. **No Destructive Rewrites**:
   - Preserve keybindings (Cmd+S, Cmd+O, Cmd+N, Cmd+Shift+P).

---

## 3. Verification Commands

Before submitting or committing changes:
```bash
# 1. Run automated test suite (53 assertions)
./test.sh

# 2. Build release application bundle
./build.sh release

# 3. Verify bundle integrity
codesign --verify --deep --strict "QuickPad.app"
```

---

## 4. Standards Reference

Refer to the shared DevKit standards in `../111iridescence-devkit/standards/`:
- `swift-macos.md`: Swift concurrency, AppKit controls, memory safety.
- `brand.md`: Studio identity `111iridescence`, privacy constraints.
