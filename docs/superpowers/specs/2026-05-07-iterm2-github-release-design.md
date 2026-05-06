# iTerm2 and GitHub Release Integration Design

Date: 2026-05-07

## Context

AmberPhosphor-theme currently ships two generated Apple Terminal profiles:

- `terminal/AmberPhosphor.terminal`
- `terminal/AmberPhosphor-ANSI.terminal`

The repo also includes a Swift generator, a Terminal.app install helper, a README, a changelog, and a GitHub Actions validation workflow. The repository is public, has no Git tags or GitHub releases yet, and already has a local GPG signing key configured as `FEA322F2C85C0E17`.

## Goals

- Add first-class iTerm2 theme support.
- Keep Terminal.app and iTerm2 themes generated from the same palette definitions.
- Keep private GPG key material local.
- Sign releases through annotated signed Git tags created locally with the default GitHub GPG key.
- Add practical GitHub free-service integration for validation, release provenance, and maintenance.

## Non-Goals

- Do not upload private GPG key material to GitHub Actions.
- Do not make GitHub Actions responsible for creating or signing release tags.
- Do not introduce a package manager or heavyweight build system.
- Do not redesign the palette or visual identity.

## Recommended Approach

Extend the existing Swift generator so it emits both Terminal.app and iTerm2 plist formats from the same two `ThemeColors` values. Store iTerm2 outputs in a new `iterm2/` directory:

- `iterm2/AmberPhosphor.itermcolors`
- `iterm2/AmberPhosphor-ANSI.itermcolors`

Add an iTerm2 import helper script in `iterm2/install-iterm2.sh`. The script will mirror the Terminal.app installer pattern: validate macOS, open each `.itermcolors` file, and print concise next steps.

Release signing remains local. A release helper will create annotated signed tags with the configured local GPG key `FEA322F2C85C0E17`, push the tag, and let GitHub Actions build the downloadable artifact bundle from that tag.

## Architecture

The generator remains the source of truth:

- `ThemeColors` holds palette values and shared metadata.
- Terminal.app generation writes `.terminal` files using archived `NSColor` and font data.
- iTerm2 generation writes XML plist `.itermcolors` files with the iTerm2 color-key schema.
- The output list maps each theme variant to both file formats.

The release workflow remains separate from local signing:

- Local machine: creates signed annotated tag.
- GitHub Actions: validates generated files, packages release artifacts, generates provenance attestation, and publishes or updates a GitHub Release for the pushed signed tag.

## Components

### Generator

Enhance `terminal/generate-terminal-themes.swift` to:

- Create `terminal/` and `iterm2/` output directories when needed.
- Generate both Terminal.app and iTerm2 files from `monochromeTheme` and `ansiTheme`.
- Encode iTerm2 colors as plist dictionaries with `Red Component`, `Green Component`, `Blue Component`, and `Alpha Component` keys.
- Preserve current Terminal.app output compatibility.

### iTerm2 Installer

Add `iterm2/install-iterm2.sh`:

- Exit with a clear message on non-macOS platforms.
- Open both `.itermcolors` files if present.
- Warn when an expected generated file is missing.
- Tell the user to import/select the profiles in iTerm2 preferences.

### Documentation

Update `README.md` to:

- Describe Terminal.app and iTerm2 support.
- List generated files by terminal application.
- Add iTerm2 quick install and manual import instructions.
- Keep regeneration instructions centered on the Swift generator.
- Clarify requirements for each terminal application.

Update `CHANGELOG.md` with an unreleased entry for:

- iTerm2 theme support.
- iTerm2 installation helper.
- GitHub release automation and provenance additions.

### GitHub Actions

Update `.github/workflows/validate.yml` to:

- Generate all theme files.
- Lint both `.terminal` and `.itermcolors` plist outputs.
- Check that regenerated outputs match committed files.
- Upload generated files as CI artifacts.

Add a release workflow triggered by version tags, such as `v*`:

- Check out the exact tag.
- Verify the tag object exists and is signed.
- Generate all theme files.
- Lint all generated plists.
- Package Terminal.app and iTerm2 themes plus install helpers into a release archive.
- Upload the archive as a workflow artifact.
- Generate a GitHub artifact attestation for the archive.
- Create or update the GitHub Release with generated release notes.

The workflow should request minimal `GITHUB_TOKEN` permissions. Release jobs need `contents: write`, `attestations: write`, and `id-token: write`; validation jobs should default to read-only permissions.

### GitHub Maintenance

Add `.github/dependabot.yml` for weekly GitHub Actions updates. GitHub documents Dependabot version updates for GitHub Actions as available for all repositories.

Add `.github/release.yml` to customize automatically generated GitHub release notes with categories for features, fixes, documentation, maintenance, and dependency updates.

## Release Process

The release process will be documented as:

1. Ensure the working tree is clean.
2. Run the generator and validation locally.
3. Update `CHANGELOG.md`.
4. Commit the release changes.
5. Create a signed annotated tag with the local GPG key:

   ```bash
   git tag -s vX.Y.Z -m "AmberPhosphor vX.Y.Z"
   ```

6. Push the tag:

   ```bash
   git push origin vX.Y.Z
   ```

7. Let GitHub Actions create the release artifacts and provenance attestation.

The private GPG key stays on the local machine. GitHub verifies the tag signature using the public GPG key already associated with the GitHub account.

## Testing

Local verification should include:

- `swift terminal/generate-terminal-themes.swift`
- `plutil -lint terminal/AmberPhosphor.terminal terminal/AmberPhosphor-ANSI.terminal`
- `plutil -lint iterm2/AmberPhosphor.itermcolors iterm2/AmberPhosphor-ANSI.itermcolors`
- A git diff check to confirm generated files are committed.

CI verification should run the same generation and plist linting, then verify no generated-file drift exists.

Release workflow verification should include:

- Signed tag validation.
- Artifact archive creation.
- Artifact attestation generation.
- Release creation or update.

## Error Handling

- Generator failures should exit non-zero through Swift runtime errors.
- Install scripts should warn for missing expected theme files instead of failing the entire import.
- CI should fail if generated output is invalid or differs from committed files.
- Release workflow should fail if the pushed tag is not a signed annotated tag.

## Open Decisions Resolved

- Release signing will use local signed annotated Git tags with `FEA322F2C85C0E17`.
- GitHub Actions will not store or use private GPG key material.
- iTerm2 themes will be committed generated artifacts, matching the current Terminal.app pattern.
