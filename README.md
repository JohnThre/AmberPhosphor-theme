# AmberPhosphor Theme

Amber phosphor (PC-12) terminal theme for Apple Terminal.app and iTerm2 on macOS.

Recreates the warm amber glow of vintage CRT terminals using the characteristic PC-12 phosphor color (`#FFB000`).

## Variants

### AmberPhosphor (Pure Monochrome)

Every color is a brightness variation of amber. Authentic single-phosphor CRT appearance where all text glows in shades of amber on a warm dark background.

### AmberPhosphor ANSI (Distinguishable Colors)

Same amber phosphor base, but ANSI colors use warm-spectrum chromatic variants (amber-red, amber-olive, warm tan) so tools like `ls`, `git diff`, and syntax highlighting remain usable while preserving the retro CRT atmosphere.

## Color Palette

### Monochrome

| Role | Color |
|------|-------|
| Background | `#1A1000` |
| Foreground | `#FFB000` |
| Bold | `#FFD066` |
| Cursor | `#FFB000` |

ANSI colors use brightness levels from `#332200` (dim) to `#FFE099` (brightest glow).

### ANSI Variant

| Role | Color |
|------|-------|
| Background | `#1A1000` |
| Foreground | `#FFB000` |
| Bold | `#FFD066` |
| Cursor | `#FFB000` |

ANSI colors use amber-tinted warm spectrum: red `#FF6622`, green `#88AA00`, yellow `#FFB000`, blue `#CC8844`, magenta `#DD7744`, cyan `#AAAA33`.

## Generated Files

### Apple Terminal.app

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

This opens both `.terminal` files, which Terminal.app imports as profiles.

### Terminal.app Manual Install

1. Double-click `terminal/AmberPhosphor.terminal` or `terminal/AmberPhosphor-ANSI.terminal`
2. Open Terminal > Settings > Profiles
3. Select the imported profile and click "Default" to set it as default

### iTerm2 Quick Install

```bash
./iterm2/install-iterm2.sh
```

This opens both `.itermcolors` files for import into iTerm2.

### iTerm2 Manual Install

1. Open iTerm2 > Settings > Profiles > Colors
2. Open Color Presets > Import
3. Select `iterm2/AmberPhosphor.itermcolors` or `iterm2/AmberPhosphor-ANSI.itermcolors`
4. Open Color Presets again and select AmberPhosphor or AmberPhosphor ANSI

## Regenerating Themes

The Terminal.app and iTerm2 theme files are generated from the Swift script:

```bash
swift terminal/generate-terminal-themes.swift
```

Requires macOS with Xcode or Command Line Tools installed.

Validate generated files with:

```bash
scripts/validate-themes.sh
```

## Release Flow

Create a release from a clean `main` branch that matches `origin/main`:

```bash
scripts/release.sh vX.Y.Z
```

The release helper validates the generated theme files, prompts for confirmation, then requires typing `yes` before it creates a local signed GPG tag, verifies it, and pushes the tag to `origin`. GitHub Actions publishes the GitHub release from that tag, uploads a release archive containing README/CHANGELOG/LICENSE plus the Terminal.app and iTerm2 theme files/install helpers, and attests that archive.

## Font

Menlo Regular 14pt — a classic macOS monospace font at a size that evokes the larger character cells of vintage CRT terminals.

## Requirements

- macOS
- Apple Terminal.app or iTerm2

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE) for details.
