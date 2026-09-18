---
name: iphone-duo
description: Adapt SwiftUI and UIKit code for iPhone Duo, Apple's folding iPhone (announced September 2026, iOS 27.1). Use when the user mentions iPhone Duo, foldables, the fold or hinge, device poses, dual displays, adaptive layout for a folding phone, or asks to audit or refactor an iOS app for Duo.
---

# iPhone Duo adaptation

## Ground rules

1. **Never invent an API.** The iOS 27.1 SDK is not public yet. If a task needs a Duo-specific symbol, say it is not verifiable and leave a `// TODO(duo):` marker. Do not guess spellings.
2. **Never invent a number.** Point dimensions, scale factor, hinge angle thresholds and safe-area insets for Duo are not published. Read them at runtime or ask; do not hard-code a value you have not seen in Apple documentation.
3. **Prefer removing assumptions over adding branches.** Aim for code that adapts to any size, not code with a special case for one device.
4. **Say what you did not verify.** No Duo simulator exists yet, so state that the result is unverified on device.

## Mental model

An outer display used when closed, a larger inner display when open, and a fold down the middle of the inner one. Opening, closing and folding are **resize events while the app runs**, not launches.

Per Apple's HIG article (see Sources): treat the outer display as **compact** width and the inner display as **regular** width. Branch on size class, never on device identity. Read the actual value at runtime (`@Environment(\.horizontalSizeClass)` / `traitCollection`) rather than assuming a device.

## What to flag and fix

| Pattern | Problem | Fix |
| --- | --- | --- |
| `UIScreen.main.bounds`, cached sizes | Wrong after any fold/unfold | `GeometryReader`, size classes, auto layout |
| Device or idiom checks | Duo is not in the list | Branch on size class |
| Interactive content centred on the fold | Sits across the hinge | Put the gap there, not a control |
| Fixed frames, hard-coded insets | Do not survive a resize | Relative sizing, safe area insets |
| `UIRequiresFullScreen`, orientation locks | Opts out of resizing | Remove |
| Blanket `.ignoresSafeArea()` | Content under reserved regions | Scope it to specific edges |
| Hand-built tab bars and toolbars | Do not adapt to side placement | `TabView`, `.toolbar`, `NavigationSplitView` |

When the fold is in the way, shift existing elements out of that region rather than designing a separate layout per pose. Scrolling content (feeds, lists, documents) is expected to cross the fold and needs no special handling.

### About grid columns

The goal is that no interactive element or focal point is centred on the fold. An even column count is the simplest reliable way to get there, because the gutter lands in the middle. An adaptive layout that places a gutter over the fold is equally valid. Do not replace a deliberate design with a mechanical "make it even" edit — explain the trade-off and let the user choose.

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

**Device branch → size class**

```swift
// Before
if UIDevice.current.userInterfaceIdiom == .phone { compactLayout() } else { wideLayout() }

// After
@Environment(\.horizontalSizeClass) private var sizeClass
var body: some View {
    sizeClass == .regular ? AnyView(wideLayout()) : AnyView(compactLayout())
}
```

**Odd columns → even columns**

```swift
// Before: with three columns the middle one sits over the fold
let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

// After: the gutter lands on the fold instead
let columns = [GridItem(.flexible()), GridItem(.flexible())]
```

## Optional tool

If the project uses **duo-kit** (https://github.com/klavyeesir/duo-kit), run its linter first and work through the findings:

```bash
swift build -c release && .build/release/DuoLint <path>
```

Exit codes: 0 clean, 1 findings, 2 tool error. If duo-kit is not present in the project, skip this step — do not install it unasked and do not invent its output.

## Workflow for an audit request

1. Run the linter if present; otherwise read the layout code directly.
2. Report findings grouped by the table above, with file and line.
3. Fix what is certain: screen bounds, device branches, fixed frames, full-screen opt-outs.
4. For anything needing an unshipped API, leave `// TODO(duo):` and say what is blocked.
5. State that nothing was verified on a Duo simulator.

## Sources

- Apple HIG, *Designing for iPhone Duo*: https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo (published 2026-09-09)
- Apple's iPhone Duo Tech Talks, linked from https://developer.apple.com/iphone-duo/

Summarised in our own words; no Apple text is reproduced. Unofficial, not affiliated with Apple. Re-verify when Xcode 27.1 ships.
