# duo-kit

**Linter, GitHub Action and AI agent skill for adapting SwiftUI/UIKit apps to iPhone Duo.**

DuoLint parses your Swift code with [SwiftSyntax](https://github.com/swiftlang/swift-syntax) — not regex — and reports layout patterns that break on iPhone Duo's two displays, its fold and its runtime size changes.

> **Status: pre-release (v0.1.x).** Apple has not shipped Xcode 27.1 / the iOS 27.1 SDK yet. Every rule here is based on published design guidance and compiles on current toolchains, but nothing has been verified against a shipping Duo SDK or simulator. See [Roadmap](#roadmap).

## Why

A foldable changes display size at runtime, and a hinge runs down the middle of the inner display. Code that assumes one fixed screen — cached screen bounds, odd column counts centred on the fold — produces visible layout bugs on the new device. Existing tools do not check for this, and AI coding agents have no training data for a phone announced in September 2026.

## Quick start

```bash
git clone https://github.com/klavyeesir/duo-kit.git
cd duo-kit
swift build -c release
.build/release/DuoLint path/to/your/ios/project
```

Example output:
Sources/GalleryView.swift:14:21: warning: [duo-screen-bounds] Use GeometryReader / size classes instead of UIScreen.main.bounds
Sources/GalleryView.swift:22:9: warning: [duo-odd-grid-columns] 3 grid columns: the middle column lands on the iPhone Duo fold. Use an even column count.


Exit codes: `0` clean, `1` findings, `2` tool error (unreadable path, bad arguments).

## Use as a GitHub Action

```yaml
- uses: klavyeesir/duo-kit@v0.1.0
  with:
    path: Sources
```

Findings appear as inline annotations on the pull request. Inputs: `path`, `format` (`github` | `text` | `sarif`), `sarif-file`, `fail-on-findings`.

For SARIF and GitHub code scanning:

```yaml
permissions:
  security-events: write
steps:
  - uses: actions/checkout@v4
  - uses: klavyeesir/duo-kit@v0.1.0
    with:
      format: sarif
      fail-on-findings: "false"
  - uses: github/codeql-action/upload-sarif@v3
    with:
      sarif_file: duolint.sarif
```

Runs on any runner with a Swift toolchain (macOS runners, or `container: swift:latest` on Linux).

For supply-chain safety, pin to a commit SHA rather than a tag: `uses: klavyeesir/duo-kit@<sha>`.

## Rules

| ID | What it flags | Why it matters on Duo |
| --- | --- | --- |
| `duo-screen-bounds` | `UIScreen.main.bounds` | The display size changes when the device is opened, closed or folded, so a value read once is wrong afterwards. Read size from the view (`GeometryReader`, size classes) instead. |
| `duo-odd-grid-columns` | Odd `GridItem` column counts (3, 5, 7…) in array literals and `Array(repeating:count:)` | With an odd count the middle column sits over the fold on the inner display. An even count puts the gap there instead. |

### Known limitations

- Column counts are only detected when written as a literal. `let n = 3; Array(repeating: …, count: n)` is not resolved.
- No cross-file or type inference; each file is parsed on its own.
- Rules cover layout patterns that are stable regardless of SDK. Rules for the new iOS 27.1 APIs are deliberately absent until those symbols can be compiled.

## AI agent skill

`skills/iphone-duo/SKILL.md` teaches coding agents (Claude Code, Antigravity, Cursor, Codex) the same rules, plus the ground rule that matters most right now: **never invent an iOS 27.1 API name or an undocumented dimension — say it is unknown instead.**

```bash
cp -r skills/iphone-duo ~/.claude/skills/
```

## Development

```bash
swift build
./scripts/test-fixtures.sh
```

Every rule has a fixture named after it in `Fixtures/bad/`, plus a look-alike correct file in `Fixtures/clean/` that must produce no findings. CI runs the fixture suite, validates the SARIF output and tests the Action itself against both fixture sets.

To add a rule: subclass `Rule` in `Sources/DuoLint/main.swift`, add it to `ruleCatalog` and to the rule list in the main loop, then add the two fixtures. No CI changes needed.

## Roadmap

- [ ] Verify every rule against Xcode 27.1 and the iPhone Duo simulator on the day the SDK ships
- [ ] Benchmark: measure agent output with and without the skill, publish the numbers
- [ ] Before/after example app
- [ ] Xcode build plugin

## License and trademarks

MIT. Unofficial project, not affiliated with or endorsed by Apple. iPhone and iPhone Duo are trademarks of Apple Inc. Design guidance is summarised in our own words from Apple's [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo); no Apple text is reproduced here.
