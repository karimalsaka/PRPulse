# Repository Guidelines

## Project Structure & Module Organization
- `PRPulse/` contains the SwiftUI application source. Entry point is `PRPulseApp.swift`.
- Views live as standalone files (for example `PRListView.swift`, `SettingsView.swift`, `OnboardingView.swift`).
- App services and state live in files like `GitHubService.swift`, `TokenManager.swift`, and `SettingsViewModel.swift`.
- Assets are in `PRPulse/Assets.xcassets`, and app configuration is in `PRPulse/Info.plist` and `PRPulse/PRPulse.entitlements`.
- Xcode project metadata is in `PRPulse.xcodeproj`.

## Build, Test, and Development Commands
- Open the project in Xcode: `open PRPulse.xcodeproj` (preferred for local development).
- Build from CLI: `xcodebuild -scheme PRPulse -configuration Debug build`.
- Run from CLI: `xcodebuild -scheme PRPulse -configuration Debug -destination 'platform=macOS' run`.
- There are no test targets in the repo currently, so `xcodebuild test` will not run anything unless you add a test target.

## Coding Style & Naming Conventions
- Swift files use 4-space indentation and standard Swift/SwiftUI naming (Types: `UpperCamelCase`, variables/functions: `lowerCamelCase`).
- Keep view files focused on a single screen or component; shared UI tokens should go in `DesignSystem.swift`.
- No formatter or linter is configured; rely on Xcode’s default formatting and keep lines concise.

## Testing Guidelines
- No automated tests are present. If you add tests, follow Xcode defaults (`PRPulseTests` / `PRPulseUITests`) and name test methods `test<Behavior>()`.
- For UI changes, include manual verification steps in the PR (for example, “verified onboarding flow and PR list filters”).

## Commit & Pull Request Guidelines
- Commit messages follow a short, imperative sentence style (e.g., “Refine UI theme and add previews”). Keep them under ~72 characters.
- PRs should include: a short summary, testing notes, and screenshots/GIFs for UI changes.
- Link related issues if applicable and call out any behavior or data changes (polling interval, filters, permissions state).

## Security & Configuration Tips
- GitHub personal access tokens are stored in `UserDefaults` via `TokenManager.swift`; avoid committing real tokens and prefer test accounts.
- The app hits GitHub’s GraphQL API; be mindful of API limits and update scopes in onboarding/permissions UI when required.
