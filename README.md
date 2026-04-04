# AmberPhosphor Theme

Amber phosphor (PC-12) terminal theme for Apple Terminal on macOS 26.4+.

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

## Installation

### Quick Install

```bash
./terminal/install-terminal.sh
```

This opens both `.terminal` files, which Terminal.app imports as profiles.

### Manual Install

1. Double-click `terminal/AmberPhosphor.terminal` or `terminal/AmberPhosphor-ANSI.terminal`
2. Open Terminal > Settings > Profiles
3. Select the imported profile and click "Default" to set it as default

## Regenerating Themes

The `.terminal` files are generated from the Swift script:

```bash
swift terminal/generate-terminal-themes.swift
```

Requires macOS with Xcode or Command Line Tools installed.

## Font

Menlo Regular 14pt — a classic macOS monospace font at a size that evokes the larger character cells of vintage CRT terminals.

## Requirements

- macOS 26.4 or later
- Apple Terminal.app

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE) for details.
