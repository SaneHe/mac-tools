# AGENTS.md

## Project Context
- This repository currently contains product and engineering documentation for `Mac Text Actions`, a macOS utility app.
- The current scope is documentation-first. Do not assume an app scaffold, build system, or runtime code already exists.
- Use the `docs/` directory as the source of truth for product intent and architecture:
  - `docs/README.md`
  - `docs/requirements/mac-text-actions-prd.md`
  - `docs/design/mac-text-actions-design.md`
  - `docs/solution/mac-text-actions-solution.md`
  - `docs/architecture/mac-text-actions-architecture.md`
  - `docs/interaction/mac-text-actions-interaction-flow.md`
  - `docs/ui/mac-text-actions-ui.md`
  - `docs/development/mac-text-actions-development-guidelines.md`
  - `docs/development/ai-prompt-templates.md`

## Product Scope
- `v1` is a `global shortcut` driven macOS text actions tool.
- It only operates on the current `selected text`.
- Supported `v1` capabilities:
  - `JSON` formatting and validation
  - timestamp to local date/time conversion
  - date string to timestamp conversion
  - `MD5` as a `secondary action`
  - quick-create macOS reminders
  - copy result
  - replace selection

## Technical Baseline
- Implementation baseline is native macOS:
  - `Swift 6`
  - `SwiftUI`
  - `AppKit` bridge
  - `MVVM + Services`
- UI direction is `Native macOS utility panel + refined polish`.
- Do not introduce a web container stack such as `Tauri` or `Electron` unless the user explicitly changes the technical direction.

## Compatibility Baseline
- Minimum supported OS is `macOS 13 Ventura`.
- Recommended development environment is `Xcode 16+`.
- Prefer supporting `Apple Silicon`; produce a `Universal` app when practical to retain `Intel Mac` compatibility.
- Treat system permissions as first-class product requirements:
  - accessibility-related capability for reading or replacing `selected text`
  - reminders authorization for reminder creation
- Treat `macOS 13` as a fully supported target only if the implementation verifies:
  - global shortcut behavior
  - floating panel focus and window behavior
  - selected text reading
  - replace selection write-back behavior

## Explicit Non-Goals
- No clipboard management
- No automatic write-back
- No batch processing
- No natural-language reminder time parsing

## Canonical Terminology
Use these terms consistently across code, docs, plans, and reviews:
- `global shortcut`
- `selected text`
- `result panel`
- `primary result`
- `secondary action`

Do not introduce alternate names for the same concepts unless the repo adopts a formal naming change.

## Detection Rules
- The authoritative detection priority lives in `docs/design/mac-text-actions-design.md`.
- Reuse that rule order instead of redefining it in new files.
- The current fixed priority is:
  1. valid `JSON`
  2. `10` digit or `13` digit timestamp
  3. parseable date string
  4. plain text

## Interaction Rules
- `JSON` default behavior is formatting only.
- `JSON Compress` is a `secondary action`.
- `MD5` is a `secondary action`.
- Automatic detection may compute and render a `primary result`, but it must not silently modify the original text.
- If `selected text` cannot be read, `clipboard fallback` is allowed, but the UI must clearly label the content source and avoid implying the result came from the live selection.

## Documentation Rules
- Keep documentation in Chinese unless the user explicitly asks for bilingual or English docs.
- Prefer Markdown for narrative docs and Mermaid for diagrams.
- When changing product behavior, update the relevant `docs/` files in the same task.
- If detection logic, UI states, or scope boundaries change, update all affected docs to keep terminology and constraints aligned.
- `docs/README.md` should remain the entry point for new contributors.
- Use `docs/development/mac-text-actions-development-guidelines.md` as the project-specific adaptation of general Swift best practices.
- Keep AI prompt guidance in `docs/development/ai-prompt-templates.md`; do not mix prompt templates into product requirement docs.
- 当前设置页的 UI 风格说明、快捷键职责和权限提示规则应同时维护在 `README.md`、`docs/README.md` 与 `docs/ui/mac-text-actions-ui.md`，避免入口文档和实现漂移。

## Code Style Baseline
- Prefer clear naming over short naming.
- Prefer `let` over `var` unless mutation is required.
- Keep functions small and single-purpose.
- Use `MARK` sections in larger Swift files.
- Do not leave maintained code as "self-explanatory only"; add concise comments for module responsibilities, non-obvious branches, and platform/workflow constraints, while avoiding redundant line-by-line narration.
- Keep business logic out of `View` types.
- Prefer `async/await` over introducing heavier async patterns by default.
- Introduce `SwiftLint` once source code is added.

## Development Principles
- Apply object-oriented design pragmatically: keep responsibilities on cohesive types, model clear service boundaries, and avoid turning `View` or coordinator types into god objects.
- Follow `SOLID` where it improves maintainability:
  - single responsibility for views, view models, services, and transformers
  - open/closed via small protocol-based seams and composable types, not speculative abstraction
  - Liskov substitution and interface segregation when introducing protocols
  - dependency inversion for platform integrations and side effects
- Follow `KISS`: prefer the simplest solution that satisfies the documented `v1` scope and macOS constraints.
- Follow `DRY`: extract shared logic only when duplication is real and stable; do not hide simple code behind premature helpers.
- Avoid over-engineering in the name of patterns. Principles serve clarity and maintainability, not architecture for its own sake.

## Implementation Guidance
- If implementation starts later, preserve the documented module boundaries:
  - app shell
  - shortcut manager
  - selection reader
  - detection engine
  - transform engine
  - action executor
  - result panel
- The current docs already lock the high-level implementation direction. Preserve that direction unless the user explicitly changes it.

## Working Style In This Repo
- Make the smallest coherent change that keeps docs and code aligned.
- Do not add speculative features beyond the documented `v1` scope unless the user asks for them.
- When editing or adding docs, prefer updating the existing canonical document instead of duplicating the same rules in multiple places.
