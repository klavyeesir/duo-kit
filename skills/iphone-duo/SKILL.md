---
name: iphone-duo
description: Adapt SwiftUI and UIKit code for iPhone Duo, Apple's folding iPhone (iOS 27.1). Use when the user mentions iPhone Duo, foldables, the fold or hinge, device poses, dual displays, reserved regions, vertical toolbars, arrangement views, adaptive layout for a folding phone, or asks to audit or refactor an iOS app for Duo.
---

# iPhone Duo adaptation

## SDK status — read this first

Verified against Apple's documentation on **2026-09-21**:

- **Xcode 27** and **iOS 27.0** shipped 2026-09-14.
- **Xcode 27.1 is still beta** (27A9269). It carries the **iOS 27.1 SDK**, where every Duo API lives.
- An **iPhone Duo Simulator runtime** now exists in Xcode 27.1 beta.
- Every Duo symbol is marked **Beta** on developer.apple.com. Spellings can change before GA.

Say this when you use any Duo API. Do not present beta symbols as settled.

## The API reference

**Before writing any iOS 27.1 Duo API, open `references/duo-api.md` next to this file and read it.** It is the verified symbol list: reserved regions, arrangement views, vertical bar placement and overflow, camera, and the simulator. Nothing here duplicates it.

## Ground rules

1. **Only use API names written in `references/duo-api.md`.** They were copied from Apple's documentation, not recalled. If a task needs a Duo symbol that is not there, say it is not verifiable, leave a `// TODO(duo):` marker, and ask. Do **not** extrapolate a sibling name from a listed one — that guess is the exact failure this skill exists to prevent.
2. **Never invent a number.** Point dimensions, scale factor, hinge angle thresholds and Duo safe-area insets are not published. Read them at runtime from a `GeometryProxy`, a reserved region frame, or safe area insets.
3. **Gate every 27.1 API** behind `if #available(iOS 27.1, *)` or `@available`, and keep a working fallback unless the deployment target is already 27.1.
4. **Prefer removing assumptions over adding branches.** Aim for code that adapts to any size, not a special case for one device.
5. **Branch on size class and reserved regions, never on device identity.**
6. **Say what you did not verify.** A Duo simulator exists now, so tell the user to run it there — and state that you did not.

## Mental model

A compact **outer display** used when closed, a larger **inner display** when open, and a **fold** down the middle of the inner one. Each display has a front camera; the inner one is hidden until active.

Opening, closing, folding and rotating are **resize events while the app runs**, not launches. Treat the outer display as **compact** width and the inner display as **regular** width.

Apple's framing: if the app already works on iPad and Mac, or was prepared for iPhone Mirroring resizing, most of the work is done.

Build-level gotcha: an app built with **Xcode 26 or earlier does not extend under the status bar and camera** on Duo. Building with Xcode 27+ is step zero.

## What to flag and fix

| Pattern | Problem | Fix |
| --- | --- | --- |
| `UIScreen.main.bounds`, cached sizes | Wrong after any fold or display transition | `GeometryReader`, scene/container bounds, size classes |
| `userInterfaceIdiom` / orientation checks | Duo is not in the list, and pose is not orientation | `horizontalSizeClass` / `verticalSizeClass` with automatic trait tracking |
| Fixed frames, hard-coded insets | Do not survive a resize | Relative sizing; layout margins and safe area insets |
| `UIRequiresFullScreen`, orientation locks | Opts out of resizing entirely | Remove |
| Blanket `.ignoresSafeArea()` | Content slides under camera and fold regions | Scope it to specific edges |
| Hand-built tab bars and toolbars | Never presented vertically | `TabView`, `.toolbar`, `NavigationSplitView` |
| Interactive content centred on the fold | Sits across the hinge | Even column counts; `ReservedRegion` for what the system does not move |
| Toolbar items with no icon | Silently dropped from vertical bars | Add an icon alongside the title |
| `HStack`/`VStack`/`ZStack` of two major panes | Does not react to the fold | `ArrangementView`, split or overlay |
| Missing `#available` around 27.1 symbols | Fails to build or crashes below 27.1 | Gate and provide a fallback |

Scrolling content — feeds, lists, documents — is **expected** to cross the fold and needs no special handling. Shift existing elements out of the folding region rather than designing a layout per pose, and avoid dramatic rearrangement as the device folds: people lose track of controls that jump.

### About grid columns

The goal is that no interactive element or focal point is centred on the fold. An even column count is the simplest reliable way there, because the gutter lands in the middle — Apple's HIG recommends exactly this. An adaptive layout that puts a gutter over the fold is equally valid. Do not mechanically rewrite a deliberate design; explain the trade-off and let the user choose.

## Examples

**Screen bounds → geometry**

```swift
// Before: read once, wrong after the device is opened
Image(photo).frame(width: UIScreen.main.bounds.width / 3)

// After: follows the container at any size
GeometryReader { geo in
    Image(photo).frame(width: geo.size.width / 3)
}
```

**ZStack → overlay arrangement, gated**

```swift
// Before: controls stay layered over the video even when the device folds
ZStack { VideoPlayer(); PlayerControls() }

// After: splits across the fold when partially open, layers otherwise
if #available(iOS 27.1, *) {
    ArrangementView { PlayerControls() } secondary: { VideoPlayer() }
        .arrangementViewStyle(.overlay)
} else {
    ZStack { VideoPlayer(); PlayerControls() }
}
```

## Tooling

If the project uses **duo-kit** (https://github.com/klavyeesir/duo-kit), run its linter first:

```bash
swift build -c release
.build/release/DuoLint <file-or-directory>...
```

Full usage: `DuoLint [--format text|sarif|github] <file-or-directory>...`. Keep `text` locally; `github` and `sarif` are for CI. Exit codes: 0 clean, 1 findings, 2 tool error — a non-zero exit on a dirty codebase is expected, not a broken tool.

Findings print as `file:line:col: warning: [rule-id] message`. The rule ids are `duo-screen-bounds`, `duo-odd-grid-columns`, `duo-ignores-safe-area` and `duo-manual-toolbar`. **The linter covers only those four patterns** — it has no rules for missing toolbar icons, missing `#available` gates, or stack-to-arrangement migrations, so read the layout code for the rest yourself.

If duo-kit is not present, skip this step — do not install it unasked and do not invent its output.

## Workflow for an audit request

1. Confirm the toolchain: Xcode 27.1 beta or later, and that the app is built with Xcode 27+ to use the full screen.
2. Run the linter if present; otherwise read the layout code directly.
3. Report findings grouped by the table above, with file and line.
4. Fix what is certain and SDK-independent first: screen bounds, idiom branches, fixed frames, full-screen opt-outs, blanket `.ignoresSafeArea()`, missing toolbar icons.
5. Read `references/duo-api.md`, then propose the 27.1-specific changes behind availability gates, each flagged as beta API.
6. For anything needing a symbol not in that reference, leave `// TODO(duo):` and say what is blocked rather than guessing.
7. Tell the user to verify in the Duo simulator across closed, open and partially folded poses in both orientations, and state that you did not run it.

## Sources

Read on 2026-09-21; full list in `references/duo-api.md`.

- Apple HIG, *Designing for iPhone Duo* — https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo
- Apple, *Preparing your app for iPhone Duo* — https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo

Summarised in our own words; no Apple text is reproduced. Unofficial, not affiliated with Apple. **Re-verify every symbol when Xcode 27.1 reaches GA.**
