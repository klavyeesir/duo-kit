---
name: iphone-duo
description: Adapt SwiftUI and UIKit code for iPhone Duo, Apple's folding iPhone (announced September 2026, iOS 27.1). Use when the user mentions iPhone Duo, foldables, the fold or hinge, device poses, dual displays, adaptive layout for a folding phone, or asks to audit or refactor an iOS app for Duo.
---

# iPhone Duo adaptation

## Ground rules

1. **Never invent an API.** The iOS 27.1 SDK is not yet public. If a task needs a Duo-specific symbol, say it is not yet verifiable and leave a `// TODO(duo):` marker. Do not guess spellings.
2. **Never invent a number.** Point dimensions, scale factor, hinge angle thresholds and safe-area insets for Duo are not published. Ask the user or read them at runtime; do not hard-code a value you have not seen in Apple documentation.
3. **Prefer removing assumptions over adding branches.** The goal is code that adapts to any size, not code with a special case for one device.
4. **Run the linter when it is available.** If `duo-kit` is in the project, run `DuoLint <path>` and work through the findings before writing new code.

## Mental model

The device has an outer display (used closed) and a larger inner display (used open), with a fold down the middle of the inner one. Size changes happen while the app is running — opening, closing and folding are resize events, not launches.

Treat the outer display as compact width and the inner display as regular width, and let layout follow the size class rather than the device identity.

## What to flag and fix

| Pattern | Problem | Fix |
| --- | --- | --- |
| `UIScreen.main.bounds`, cached screen sizes | Wrong after any fold/unfold | `GeometryReader`, size classes, auto layout |
| Device or idiom checks (`userInterfaceIdiom`, model strings) | Duo is not in the list | Branch on size class, not device |
| Odd grid column counts (3, 5, 7) | Middle column sits on the fold | Even column count |
| Fixed frames and hard-coded insets | Do not survive a resize | Relative sizing, safe area insets |
| `UIRequiresFullScreen`, orientation locks | Opts out of resizing | Remove |
| Blanket `.ignoresSafeArea()` | Content under reserved regions | Scope it to the edges you mean |
| Hand-built tab bars and toolbars | Do not adapt to side placement | Native `TabView`, `.toolbar`, `NavigationSplitView` |

When content must move because the fold is in the way, shift existing elements out of the fold region rather than redesigning a separate layout for that pose. Scrolling content (feeds, lists, documents) is exempt — it is expected to cross the fold.

## Workflow for an audit request

1. Run `DuoLint` on the target if available; otherwise read the layout code directly.
2. Report findings grouped by the table above, each with file and line.
3. Fix the ones that are certain (screen bounds, odd columns, fixed frames, full-screen opt-outs).
4. For anything that needs an unshipped API, leave a `// TODO(duo):` marker and tell the user what is blocked and why.
5. Say explicitly that nothing was verified on a Duo simulator, if that is the case.

## Source

Design guidance summarised from Apple's Human Interface Guidelines article "Designing for iPhone Duo" (published September 9, 2026) and the accompanying Tech Talks. Unofficial; not affiliated with Apple. Re-verify when Xcode 27.1 ships.
