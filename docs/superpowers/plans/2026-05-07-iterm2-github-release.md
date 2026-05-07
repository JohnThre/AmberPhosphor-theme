# iTerm2 and GitHub Release Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add generated iTerm2 themes, local signed-release helpers, and GitHub free-service release automation.

**Architecture:** Keep the Swift generator as the single palette source of truth and emit both Terminal.app and iTerm2 plist files from the same theme definitions. Add small shell scripts for local validation and signed releases, then have GitHub Actions call the same validation path and package attested release artifacts from signed tags.

**Tech Stack:** Swift script with Foundation/AppKit, shell scripts, macOS `plutil`, Git, GitHub Actions, Dependabot, GitHub Releases, artifact attestations.

---

## File Structure

- Modify `terminal/generate-terminal-themes.swift`: add iTerm2 plist generation, output directory creation, and shared output metadata.
- Create `iterm2/AmberPhosphor.itermcolors`: generated iTerm2 monochrome theme.
- Create `iterm2/AmberPhosphor-ANSI.itermcolors`: generated iTerm2 ANSI theme.
- Create `iterm2/install-iterm2.sh`: macOS import helper for iTerm2 files.
- Create `scripts/validate-themes.sh`: local and CI validation entrypoint.
- Create `scripts/release.sh`: local signed-tag release helper using the configured GPG key.
- Modify `.github/workflows/validate.yml`: call validation script and upload generated theme artifacts.
- Create `.github/workflows/release.yml`: validate signed tags, package artifacts, attest archive provenance, and publish GitHub releases.
- Create `.github/dependabot.yml`: weekly GitHub Actions dependency updates.
- Create `.github/release.yml`: generated release note categories.
- Modify `README.md`: document Terminal.app and iTerm2 installation, regeneration, validation, and release flow.
- Modify `CHANGELOG.md`: add unreleased entries.

## Task 1: Add iTerm2 Generation

**Files:**
- Modify: `terminal/generate-terminal-themes.swift`
- Generated: `iterm2/AmberPhosphor.itermcolors`
- Generated: `iterm2/AmberPhosphor-ANSI.itermcolors`

- [ ] **Step 1: Run the current generator baseline**

Run:

```bash
swift terminal/generate-terminal-themes.swift
```

Expected: PASS with output mentioning the two existing `.terminal` files.

- [ ] **Step 2: Replace the generator with a dual-output implementation**

Edit `terminal/generate-terminal-themes.swift` so it contains the existing palette values and these added helpers:

```swift
struct ThemeOutput {
    let theme: ThemeColors
    let terminalFilename: String
    let iterm2Filename: String
}

struct RGBColor {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
}

func hexToRGBColor(_ hex: String, alpha: Double = 1.0) -> RGBColor {
    let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    let scanner = Scanner(string: h)
    var rgb: UInt64 = 0
    scanner.scanHexInt64(&rgb)
    return RGBColor(
        red: Double((rgb >> 16) & 0xFF) / 255.0,
        green: Double((rgb >> 8) & 0xFF) / 255.0,
        blue: Double(rgb & 0xFF) / 255.0,
        alpha: alpha
    )
}

func xmlEscaped(_ value: String) -> String {
    value
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
        .replacingOccurrences(of: "'", with: "&apos;")
}

func plistColorDict(_ color: RGBColor) -> String {
    """
    \t<dict>
    \t\t<key>Alpha Component</key>
    \t\t<real>\(color.alpha)</real>
    \t\t<key>Blue Component</key>
    \t\t<real>\(color.blue)</real>
    \t\t<key>Color Space</key>
    \t\t<string>sRGB</string>
    \t\t<key>Green Component</key>
    \t\t<real>\(color.green)</real>
    \t\t<key>Red Component</key>
    \t\t<real>\(color.red)</real>
    \t</dict>
    """
}
```

Add `generateIterm2Plist(_:)` with this key mapping:

```swift
func generateIterm2Plist(_ theme: ThemeColors) -> String {
    let colors: [(String, RGBColor)] = [
        ("Ansi 0 Color", hexToRGBColor(theme.ansiBlack)),
        ("Ansi 1 Color", hexToRGBColor(theme.ansiRed)),
        ("Ansi 2 Color", hexToRGBColor(theme.ansiGreen)),
        ("Ansi 3 Color", hexToRGBColor(theme.ansiYellow)),
        ("Ansi 4 Color", hexToRGBColor(theme.ansiBlue)),
        ("Ansi 5 Color", hexToRGBColor(theme.ansiMagenta)),
        ("Ansi 6 Color", hexToRGBColor(theme.ansiCyan)),
        ("Ansi 7 Color", hexToRGBColor(theme.ansiWhite)),
        ("Ansi 8 Color", hexToRGBColor(theme.ansiBrightBlack)),
        ("Ansi 9 Color", hexToRGBColor(theme.ansiBrightRed)),
        ("Ansi 10 Color", hexToRGBColor(theme.ansiBrightGreen)),
        ("Ansi 11 Color", hexToRGBColor(theme.ansiBrightYellow)),
        ("Ansi 12 Color", hexToRGBColor(theme.ansiBrightBlue)),
        ("Ansi 13 Color", hexToRGBColor(theme.ansiBrightMagenta)),
        ("Ansi 14 Color", hexToRGBColor(theme.ansiBrightCyan)),
        ("Ansi 15 Color", hexToRGBColor(theme.ansiBrightWhite)),
        ("Background Color", hexToRGBColor(theme.background)),
        ("Bold Color", hexToRGBColor(theme.boldText)),
        ("Cursor Color", hexToRGBColor(theme.cursor)),
        ("Cursor Text Color", hexToRGBColor(theme.background)),
        ("Foreground Color", hexToRGBColor(theme.foreground)),
        ("Selected Text Color", hexToRGBColor(theme.background)),
        ("Selection Color", RGBColor(red: Double(theme.selectionR), green: Double(theme.selectionG), blue: Double(theme.selectionB), alpha: Double(theme.selectionA))),
    ]

    var xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    """

    for (key, color) in colors {
        xml += "\n\t<key>\(xmlEscaped(key))</key>\n"
        xml += plistColorDict(color)
    }

    xml += """

    </dict>
    </plist>
    """

    return xml
}
```

Update the main section to compute `repoRoot`, create both output directories, and write both formats:

```swift
let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0])
let scriptDir = scriptURL.deletingLastPathComponent()
let repoRoot = scriptDir.lastPathComponent == "terminal"
    ? scriptDir.deletingLastPathComponent()
    : scriptDir
let terminalDir = repoRoot.appendingPathComponent("terminal")
let iterm2Dir = repoRoot.appendingPathComponent("iterm2")

try! FileManager.default.createDirectory(at: terminalDir, withIntermediateDirectories: true)
try! FileManager.default.createDirectory(at: iterm2Dir, withIntermediateDirectories: true)

let outputs: [ThemeOutput] = [
    ThemeOutput(theme: monochromeTheme, terminalFilename: "AmberPhosphor.terminal", iterm2Filename: "AmberPhosphor.itermcolors"),
    ThemeOutput(theme: ansiTheme, terminalFilename: "AmberPhosphor-ANSI.terminal", iterm2Filename: "AmberPhosphor-ANSI.itermcolors"),
]

for output in outputs {
    let terminalPath = terminalDir.appendingPathComponent(output.terminalFilename)
    try! generateTerminalPlist(output.theme).write(to: terminalPath, atomically: true, encoding: .utf8)
    print("Generated: \(terminalPath.path)")

    let iterm2Path = iterm2Dir.appendingPathComponent(output.iterm2Filename)
    try! generateIterm2Plist(output.theme).write(to: iterm2Path, atomically: true, encoding: .utf8)
    print("Generated: \(iterm2Path.path)")
}

print("Done. Import .terminal files into Terminal.app or .itermcolors files into iTerm2.")
```

- [ ] **Step 3: Generate all theme files**

Run:

```bash
swift terminal/generate-terminal-themes.swift
```

Expected: PASS with four generated file paths, including both `iterm2/*.itermcolors`.

- [ ] **Step 4: Validate generated plists**

Run:

```bash
plutil -lint terminal/AmberPhosphor.terminal terminal/AmberPhosphor-ANSI.terminal iterm2/AmberPhosphor.itermcolors iterm2/AmberPhosphor-ANSI.itermcolors
```

Expected: PASS with `OK` for all four files.

- [ ] **Step 5: Inspect iTerm2 plist keys**

Run:

```bash
plutil -p iterm2/AmberPhosphor.itermcolors | rg '"Ansi 0 Color"|"Background Color"|"Foreground Color"|"Selection Color"'
```

Expected: PASS with those four top-level keys present.

- [ ] **Step 6: Commit generated iTerm2 support**

Run:

```bash
git add terminal/generate-terminal-themes.swift terminal/AmberPhosphor.terminal terminal/AmberPhosphor-ANSI.terminal iterm2/AmberPhosphor.itermcolors iterm2/AmberPhosphor-ANSI.itermcolors
git commit -m "Add generated iTerm2 themes"
```

Expected: commit succeeds.

## Task 2: Add Local Install and Validation Scripts

**Files:**
- Create: `iterm2/install-iterm2.sh`
- Create: `scripts/validate-themes.sh`

- [ ] **Step 1: Create the iTerm2 installer**

Create `iterm2/install-iterm2.sh`:

```bash
#!/bin/bash

# AmberPhosphor iTerm2 Installation Script
# Imports theme presets into iTerm2 on macOS
# License: GPL v3+

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
    Darwin*)
        ;;
    *)
        echo "This script is for macOS. iTerm2 is a macOS application."
        echo "On macOS, run: $0"
        exit 1
        ;;
esac

echo "Installing AmberPhosphor themes for iTerm2..."

for f in AmberPhosphor.itermcolors AmberPhosphor-ANSI.itermcolors; do
    if [[ -f "$SCRIPT_DIR/$f" ]]; then
        open "$SCRIPT_DIR/$f"
        echo "  Imported: $f"
    else
        echo "  Warning: $f not found, skipping"
    fi
done

echo ""
echo "Done. Presets were opened for import into iTerm2."
echo "Open iTerm2 > Settings > Profiles > Colors > Color Presets and select AmberPhosphor or AmberPhosphor ANSI."
echo ""
```

- [ ] **Step 2: Create the validation script**

Create `scripts/validate-themes.sh`:

```bash
#!/bin/bash

# Validates generated AmberPhosphor theme files.
# License: GPL v3+

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

swift terminal/generate-terminal-themes.swift

plutil -lint \
    terminal/AmberPhosphor.terminal \
    terminal/AmberPhosphor-ANSI.terminal \
    iterm2/AmberPhosphor.itermcolors \
    iterm2/AmberPhosphor-ANSI.itermcolors

git diff --exit-code -- \
    terminal/AmberPhosphor.terminal \
    terminal/AmberPhosphor-ANSI.terminal \
    iterm2/AmberPhosphor.itermcolors \
    iterm2/AmberPhosphor-ANSI.itermcolors
```

- [ ] **Step 3: Make scripts executable**

Run:

```bash
chmod +x iterm2/install-iterm2.sh scripts/validate-themes.sh
```

Expected: PASS with no output.

- [ ] **Step 4: Run validation script**

Run:

```bash
scripts/validate-themes.sh
```

Expected: PASS with generated file messages, plist `OK` results, and no git diff output.

- [ ] **Step 5: Commit scripts**

Run:

```bash
git add iterm2/install-iterm2.sh scripts/validate-themes.sh
git commit -m "Add iTerm2 installer and theme validation script"
```

Expected: commit succeeds.

## Task 3: Add GitHub Validation and Release Automation

**Files:**
- Modify: `.github/workflows/validate.yml`
- Create: `.github/workflows/release.yml`
- Create: `.github/dependabot.yml`
- Create: `.github/release.yml`

- [ ] **Step 1: Update validation workflow**

Replace `.github/workflows/validate.yml` with:

```yaml
name: Validate Theme

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read

jobs:
  validate:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate generated themes
        run: scripts/validate-themes.sh

      - name: Upload generated themes
        uses: actions/upload-artifact@v4
        with:
          name: amberphosphor-themes
          path: |
            terminal/*.terminal
            iterm2/*.itermcolors
          if-no-files-found: error
```

- [ ] **Step 2: Create release workflow**

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - "v*"

permissions:
  contents: write
  attestations: write
  id-token: write

jobs:
  release:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Verify signed annotated tag
        run: |
          set -euo pipefail
          tag="${GITHUB_REF_NAME}"
          test "$(git cat-file -t "$tag")" = "tag"
          git tag -v "$tag"

      - name: Validate generated themes
        run: scripts/validate-themes.sh

      - name: Package release archive
        run: |
          set -euo pipefail
          version="${GITHUB_REF_NAME}"
          dist_dir="dist/AmberPhosphor-theme-${version}"
          mkdir -p "$dist_dir/terminal" "$dist_dir/iterm2"
          cp README.md CHANGELOG.md LICENSE "$dist_dir/"
          cp terminal/*.terminal terminal/install-terminal.sh "$dist_dir/terminal/"
          cp iterm2/*.itermcolors iterm2/install-iterm2.sh "$dist_dir/iterm2/"
          cd dist
          zip -r "AmberPhosphor-theme-${version}.zip" "AmberPhosphor-theme-${version}"

      - name: Upload release archive artifact
        uses: actions/upload-artifact@v4
        with:
          name: AmberPhosphor-theme-${{ github.ref_name }}
          path: dist/AmberPhosphor-theme-${{ github.ref_name }}.zip
          if-no-files-found: error

      - name: Attest release archive
        uses: actions/attest-build-provenance@v2
        with:
          subject-path: dist/AmberPhosphor-theme-${{ github.ref_name }}.zip

      - name: Create GitHub Release
        env:
          GH_TOKEN: ${{ github.token }}
        run: |
          set -euo pipefail
          archive="dist/AmberPhosphor-theme-${GITHUB_REF_NAME}.zip"
          if gh release view "$GITHUB_REF_NAME" >/dev/null 2>&1; then
            gh release upload "$GITHUB_REF_NAME" "$archive" --clobber
          else
            gh release create "$GITHUB_REF_NAME" "$archive" --verify-tag --generate-notes
          fi
```

- [ ] **Step 3: Add Dependabot config**

Create `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "github-actions"
```

- [ ] **Step 4: Add generated release notes config**

Create `.github/release.yml`:

```yaml
changelog:
  categories:
    - title: Features
      labels:
        - enhancement
        - feature
    - title: Fixes
      labels:
        - bug
        - fix
    - title: Documentation
      labels:
        - documentation
    - title: Maintenance
      labels:
        - chore
        - maintenance
    - title: Dependency Updates
      labels:
        - dependencies
    - title: Other Changes
      labels:
        - "*"
  exclude:
    labels:
      - skip-changelog
    authors:
      - dependabot
```

- [ ] **Step 5: Validate workflow YAML presence**

Run:

```bash
rg -n "attest-build-provenance|upload-artifact|package-ecosystem|generate-notes" .github
```

Expected: PASS with matches in the new and updated GitHub config files.

- [ ] **Step 6: Commit GitHub automation**

Run:

```bash
git add .github/workflows/validate.yml .github/workflows/release.yml .github/dependabot.yml .github/release.yml
git commit -m "Add GitHub release automation"
```

Expected: commit succeeds.

## Task 4: Add Local Signed Release Helper

**Files:**
- Create: `scripts/release.sh`

- [ ] **Step 1: Create release helper**

Create `scripts/release.sh`:

```bash
#!/bin/bash

# Creates and pushes a signed AmberPhosphor release tag.
# License: GPL v3+

set -euo pipefail

SIGNING_KEY="FEA322F2C85C0E17"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 vX.Y.Z"
    exit 1
fi

version="$1"

case "$version" in
    v[0-9]*.[0-9]*.[0-9]*)
        ;;
    *)
        echo "Version must look like vX.Y.Z, for example v1.1.0"
        exit 1
        ;;
esac

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree is not clean. Commit or stash changes before releasing."
    exit 1
fi

scripts/validate-themes.sh

git config user.signingkey "$SIGNING_KEY"
git tag -s "$version" -m "AmberPhosphor $version"
git tag -v "$version"
git push origin "$version"

echo "Pushed signed release tag $version."
echo "GitHub Actions will build the release archive and attestation."
```

- [ ] **Step 2: Make release helper executable**

Run:

```bash
chmod +x scripts/release.sh
```

Expected: PASS with no output.

- [ ] **Step 3: Verify helper rejects missing version**

Run:

```bash
scripts/release.sh
```

Expected: FAIL with `Usage: scripts/release.sh vX.Y.Z`.

- [ ] **Step 4: Verify helper references the configured signing key**

Run:

```bash
rg -n "FEA322F2C85C0E17|git tag -s|git push origin" scripts/release.sh
```

Expected: PASS with all three release-signing lines found.

- [ ] **Step 5: Commit release helper**

Run:

```bash
git add scripts/release.sh
git commit -m "Add signed release helper"
```

Expected: commit succeeds.

## Task 5: Update Documentation

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Update README**

Revise `README.md` so it includes these sections and commands:

```markdown
## Supported Terminals

- Apple Terminal.app on macOS
- iTerm2 on macOS

## Generated Files

### Terminal.app

- `terminal/AmberPhosphor.terminal`
- `terminal/AmberPhosphor-ANSI.terminal`

### iTerm2

- `iterm2/AmberPhosphor.itermcolors`
- `iterm2/AmberPhosphor-ANSI.itermcolors`

## Installation

### Terminal.app Quick Install

```bash
./terminal/install-terminal.sh
```

### iTerm2 Quick Install

```bash
./iterm2/install-iterm2.sh
```

### iTerm2 Manual Install

1. Double-click `iterm2/AmberPhosphor.itermcolors` or `iterm2/AmberPhosphor-ANSI.itermcolors`
2. Open iTerm2 > Settings > Profiles > Colors
3. Choose the imported preset from Color Presets

## Regenerating and Validating Themes

```bash
swift terminal/generate-terminal-themes.swift
scripts/validate-themes.sh
```

## Releases

Releases are signed locally with the configured GPG key and published from GitHub Actions after a signed tag is pushed:

```bash
scripts/release.sh vX.Y.Z
```
```

Keep the existing palette and variant descriptions, but change Terminal-only wording to mention both supported terminal applications.

- [ ] **Step 2: Update changelog**

Add this entry at the top of `CHANGELOG.md`:

```markdown
## [Unreleased]

### Added
- iTerm2 theme generation for AmberPhosphor and AmberPhosphor ANSI
- iTerm2 installation helper script
- Shared local validation script for generated theme files
- Signed release helper for local GPG-tagged releases
- GitHub Actions release workflow with artifact upload and provenance attestation
- Dependabot configuration for GitHub Actions updates
- GitHub generated release notes configuration
```

- [ ] **Step 3: Run validation after docs changes**

Run:

```bash
scripts/validate-themes.sh
```

Expected: PASS.

- [ ] **Step 4: Commit docs**

Run:

```bash
git add README.md CHANGELOG.md
git commit -m "Document iTerm2 and signed releases"
```

Expected: commit succeeds.

## Task 6: Final Verification

**Files:**
- Verify all changed files.

- [ ] **Step 1: Run full validation**

Run:

```bash
scripts/validate-themes.sh
```

Expected: PASS.

- [ ] **Step 2: Check generated-file cleanliness**

Run:

```bash
git status --short
```

Expected: no output.

- [ ] **Step 3: Confirm release workflow can detect unsigned lightweight tags by construction**

Run:

```bash
rg -n 'git cat-file -t "\\$tag"|git tag -v "\\$tag"|gh release create' .github/workflows/release.yml
```

Expected: PASS with the signed tag verification and release creation lines.

- [ ] **Step 4: Confirm release helper uses local signing**

Run:

```bash
rg -n 'SIGNING_KEY="FEA322F2C85C0E17"|git tag -s "\\$version"' scripts/release.sh
```

Expected: PASS with the signing key and signed-tag command.

- [ ] **Step 5: Review final history**

Run:

```bash
git log --oneline -8
```

Expected: recent commits show the spec plus the implementation commits from Tasks 1-5.

