# duo-kit

**A linter, GitHub Action and agent skill for adapting iOS apps to iPhone Duo.**

DuoLint parses Swift with [SwiftSyntax](https://github.com/swiftlang/swift-syntax) — a real parser, not regex — and reports layout patterns that break on iPhone Duo's two displays, its fold, and its runtime size changes.

> **Pre-release (v0.1.x).** Xcode 27.1 and the iOS 27.1 SDK are not out yet. Every rule here targets layout patterns that hold regardless of SDK, and the project compiles on current toolchains — but nothing has been verified on a Duo simulator. See [Roadmap](#roadmap).

## Why this exists

A foldable changes display size while the app is running, and a hinge runs down the middle of the inner display. Code that assumes one fixed screen produces visible bugs on the new device. Existing Swift linters do not check for this, and coding agents have no training data for a phone announced in September 2026.

## Quick start

```bash
git clone https://github.com/klavyeesir/duo-kit.git
cd duo-kit
swift build -c release
.build/release/DuoLint path/to/your/ios/project
```

Sources/GalleryView.swift:14:21: warning: [duo-screen-bounds] Use GeometryReader / size classes instead of UIScreen.main.bounds
Sources/ReaderView.swift:31:9: warning: [duo-manual-toolbar] Hand-built toolbar (3 buttons separated by Spacer): use .toolbar so bars adapt to side placement and the fold on iPhone Duo.


Exit codes: `0` clean, `1` findings, `2` tool error. Output formats: `--format text` (default), `github` (inline PR annotations), `sarif`.

## GitHub Action

```yaml
- uses: klavyeesir/duo-kit@v0.1.0
  with:
    path: Sources
```

Findings appear as annotations on the changed lines of a pull request. Inputs: `path`, `format`, `sarif-file`, `fail-on-findings`.

<details>
<summary>SARIF and code scanning</summary>

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
</details>

Runs on any runner with a Swift toolchain (macOS runners, or `container: swift:latest` on Linux). Pin to a commit SHA rather than a tag for supply-chain safety.

## Rules

| ID | Flags | Why it matters on Duo |
| --- | --- | --- |
| `duo-screen-bounds` | `UIScreen.main.bounds` | Display size changes when the device is opened, closed or folded, so a value read once is wrong afterwards. |
| `duo-odd-grid-columns` | Odd `GridItem` column counts in literals and `Array(repeating:count:)` | With an odd count the middle column sits over the fold; an even count puts the gutter there instead. |
| `duo-ignores-safe-area` | `.ignoresSafeArea()` with no arguments | Unscoped, it also ignores the reserved regions around the camera and the fold. |
| `duo-manual-toolbar` | `HStack` of buttons separated by `Spacer()` | Hand-built bars do not follow the system when bars move to the side of the display. |

Each rule has a fixture that must be caught and a look-alike correct file that must not be, both enforced in CI.

### Known limitations

- Column counts are only detected as literals; `count: n` with a variable is not resolved.
- Each file is parsed independently — no cross-file or type inference.
- No rules for the new iOS 27.1 APIs. Their spellings cannot be compiled yet, so guessing them would produce exactly the kind of error this project exists to prevent.

## Agent skill

`skills/iphone-duo/SKILL.md` teaches coding agents (Claude Code, Antigravity, Cursor, Codex) the same rules, plus before/after examples and the ground rule that matters most right now: **never invent an iOS 27.1 API name or an undocumented dimension — say it is unknown instead.**

```bash
cp -r skills/iphone-duo ~/.claude/skills/
```

### Does the skill actually help?

We measure instead of claiming. `benchmarks/` holds the tasks, the raw agent outputs and the scoring script.

| Task | Without skill | With skill |
| --- | --- | --- |
| photo-grid (cached bounds, odd columns) | 3/3 | 3/3 |

So far: **no measurable difference on this task.** Both patterns in it are things a current model already fixes when asked to make a layout adaptive, so the task does not isolate Duo-specific knowledge. Harder tasks are in progress. Results will be published as they come out, including the ones that show no effect.

## Development

```bash
swift build
./scripts/test-fixtures.sh
```

To add a rule: subclass `Rule` in `Sources/DuoLint/main.swift`, register it in `ruleCatalog` and the rule list, then add `Fixtures/bad/<rule-id>.swift` and a clean counterpart. CI needs no changes.

CI runs the fixture suite, validates the SARIF output, and tests the Action itself against both fixture sets.

## Roadmap

- [ ] Verify every rule against Xcode 27.1 and the Duo simulator the day the SDK ships
- [ ] Benchmark tasks that isolate Duo-specific knowledge
- [ ] Before/after example app
- [ ] Xcode build plugin

## License and trademarks

MIT. Unofficial project, not affiliated with or endorsed by Apple. iPhone and iPhone Duo are trademarks of Apple Inc. Design guidance is summarised in our own words from Apple's [Designing for iPhone Duo](https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo); no Apple text is reproduced here.
