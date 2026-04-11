# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`Mac Text Actions` is a native macOS utility app that provides text transformation capabilities via a global shortcut. The repository contains both implementation code and product documentation. The app operates on the currently selected text and supports JSON formatting, timestamp/date conversion, MD5 hashing, and macOS reminders creation.

## Documentation Source of Truth

- `README.md` is the repository homepage and should stay concise.
- `docs/README.md` is the documentation index for new contributors.
- `docs/product.md` is the authoritative source for product behavior, scope, detection order, and error rules.
- `docs/implementation.md` is the authoritative source for technical baseline, module boundaries, runtime flow, and verification requirements.
- `docs/ui/mac-text-actions-ui.md` is the authoritative source for menu, settings, permissions messaging, and `result panel` UI behavior.
- When settings-window responsibilities, mode-switch shortcuts, or permissions hints change, keep `README.md`, `docs/README.md`, and `docs/ui/mac-text-actions-ui.md` aligned.

## Technical Stack

- **Language**: Swift 6
- **UI**: SwiftUI (main UI) + AppKit (system bridge)
- **Architecture**: MVVM + Services
- **Concurrency**: async/await
- **Minimum OS**: macOS 13 Ventura (recommended: macOS 14+)
- **Build**: Xcode 16+
- **Project Type**: Swift Package with a generated macOS `.app` workflow via `Makefile`

## Common Commands

```bash
# Show available commands
make help

# Run all tests
make test

# Build package targets and local dev app bundle
make build

# Build the local dev app bundle only
make build-app

# Build the production app bundle template under ./dist
make build-prod-app

# Run a single test
swift test --filter MacTextActionsCoreTests/TestName

# Lint code (after adding SwiftLint)
make lint
```

## Core Modules

The app is organized into these modules:

1. **App Shell** - Application lifecycle, menu bar entry, settings, permissions
2. **Shortcut Manager** - Global shortcut registration and event dispatch
3. **Selection Reader** - Reads selected text from the foreground app
4. **Detection Engine** - Identifies input type (JSON → timestamp → date string → plain text)
5. **Transform Engine** - Generates primary result and secondary actions
6. **Action Executor** - Executes Copy, Replace, Compress, MD5, Reminder
7. **Result Panel** - Renders results and user interactions

## Detection Priority

The authoritative detection order is fixed in `docs/product.md`:
1. Valid JSON
2. 10 or 13 digit timestamp
3. Parseable date string
4. Plain text

## Key Conventions

- Use Chinese for all documentation
- Prefer clear naming over short naming
- Prefer `let` over `var`
- Keep functions small and single-purpose
- Use `MARK` sections in larger Swift files
- Keep business logic out of View types
- SwiftLint rules target code cleanliness, not unnecessary suppression of normal expressions

## System Permissions

- Accessibility permission for reading/replacing selected text
- Reminders authorization for reminder creation
- Permissions must be visible states, not implicit failures

## Non-Goals (v1)

- No clipboard management
- No automatic write-back
- No batch processing
- No natural-language reminder time parsing
