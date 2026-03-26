# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`Mac Text Actions` is a macOS utility app that provides text transformation capabilities via a global shortcut. It operates on the currently selected text and supports JSON formatting, timestamp/date conversion, MD5 hashing, and macOS reminders creation.

## Technical Stack

- **Language**: Swift 6
- **UI**: SwiftUI (main UI) + AppKit (system bridge)
- **Architecture**: MVVM + Services
- **Concurrency**: async/await
- **Minimum OS**: macOS 13 Ventura (recommended: macOS 14+)
- **Build**: Xcode 16+

## Common Commands

```bash
# Build project
xcodebuild build -scheme MacTextActions

# Run tests
xcodebuild test -scheme MacTextActions

# Run a single test
xcodebuild test -scheme MacTextActions -only-testing:TestTarget/TestClass/testMethod

# Lint code (after adding SwiftLint)
swiftlint
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

The authoritative detection order is fixed in `docs/design/mac-text-actions-design.md`:
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
- SwiftLint rules target code cleanliness, not压制 normal expressions

## System Permissions

- Accessibility permission for reading/replacing selected text
- Reminders authorization for reminder creation
- Permissions must be visible states, not implicit failures

## Non-Goals (v1)

- No clipboard management
- No clipboard fallback
- No automatic write-back
- No batch processing
- No natural-language reminder time parsing