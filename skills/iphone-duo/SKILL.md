---
name: iphone-duo
description: Adapt SwiftUI and UIKit code for iPhone Duo, Apple's folding iPhone (iOS 27.1). Use when the user mentions iPhone Duo, foldables, the fold or hinge, device poses, dual displays, reserved regions, vertical toolbars, arrangement views, adaptive layout for a folding phone, or asks to audit or refactor an iOS app for Duo.
---

# iPhone Duo adaptation

## SDK status — read this first

Verified against Apple's documentation on **2026-09-21**:

- **Xcode 27 (27A266a)** and **iOS 27.0** shipped 2026-09-14.
- **Xcode 27.1 is still beta** (27A9269, seeded 2026-09-18). It carries the **iOS 27.1 SDK**, which is where every Duo API lives.
- An **iPhone Duo Simulator runtime** now exists in Xcode 27.1 beta.
- Every Duo symbol in this file is marked **Beta** on developer.apple.com. **Spellings and signatures can change before GA.**

Tell the user this when you use any API below. Do not present beta symbols as settled.

## Ground rules

1. **Only use the API names written in this file.** They were copied from Apple's documentation, not recalled. If a task needs a Duo symbol that is not listed here, say it is not verifiable, leave a `// TODO(duo):` marker, and ask. Do **not** extrapolate a sibling name from one that is listed — guessing a `reservedRegions` variant or an `.arrangementViewStyle(.foo)` you have not seen is the exact failure this skill exists to prevent.
2. **Never invent a number.** Point dimensions, scale factor, hinge angle thresholds and Duo safe-area insets are not published. Read them at runtime from a `GeometryProxy`, a reserved region frame, or safe area insets. Never hard-code one.
3. **Gate every 27.1 API.** These symbols do not exist on iOS 27.0 and earlier. Use `if #available(iOS 27.1, *)` or `@available`, and keep a working fallback path unless the deployment target is already 27.1.
4. **Prefer removing assumptions over adding branches.** Aim for code that adapts to any size, not code with a special case for one device.
5. **Branch on size class and reserved regions, never on device identity.** `userInterfaceIdiom` and `UIInterfaceOrientation` are wrong inputs for layout decisions.
6. **Say what you did not verify.** A Duo simulator exists now, so "run it in the Duo simulator and check each pose" is a real instruction — give it, and state that you did not run it yourself.

## Mental model

A compact **outer display** used when closed, a larger **inner display** when open, and a **fold** down the middle of the inner one. Each display has a front camera; the inner one is hidden until active.

Opening, closing, folding and rotating are **resize events while the app runs**, not launches. Treat the outer display as **compact** width and the inner display as **regular** width.

Apple's own framing: if the app already works on iPad and Mac, or was prepared for iPhone Mirroring resizing, most of the work is done.

One build-level gotcha: an app built with **Xcode 26 or earlier does not extend under the status bar and camera** on Duo. Building with Xcode 27+ is step zero.

## Reserved regions

iOS models hardware intrusions as **reserved regions**, of two kinds:

- A **division** — the folding region splitting one large view into smaller usable areas. Active only when the device is *partially* open.
- An **occlusion** — hardware covering content. The **outer** front camera always occludes; the **inner** front camera occludes only while the camera is active.

A region can be **active or inactive**, so query it per layout pass rather than caching.

System components (alerts, context menus, sheets, split views) adapt on their own. Custom views do not, and this is the API for them:

```swift
// SwiftUI — via GeometryProxy
GeometryReader { proxy in
    let regions = proxy.reservedRegions(kind: /* ... */, options: /* ... */,
                                        layoutDirectionBehavior: /* ... */)
    // Inspect each ReservedRegion frame and lay out around it.
}
```

```swift
// UIKit — on UIView
let regions: [UIView.ReservedRegion] = view.reservedRegions(kind: /* ... */, options: /* ... */)
```

Types: `ReservedRegion` (SwiftUI), `UIView.ReservedRegion` (UIKit).

The argument values for `kind:` and `options:` are **not recorded in this skill**. Read them from the SDK or Apple's reference page before writing a call — do not guess an enum case.

## Arrangement views

`ArrangementView` (SwiftUI) / `UIArrangementViewController` (UIKit) — iOS 27.1+, **Beta**. A container for a **primary** and a **secondary** view that re-lays them out for the current size, size class and reserved regions.

```swift
nonisolated struct ArrangementView<Primary, Secondary> where Primary: View, Secondary: View
```

Two styles:

- **Split** — side by side when wider than tall, stacked when taller than wide. Adapts around the folding region. Reach for it when the code already uses an `HStack` or `VStack`.
- **Overlay** — primary layered over secondary in z-order. When the device is *partially* open it splits instead: primary to the trailing/bottom side of the fold, secondary to the leading/top side. Reach for it when the code already uses a `ZStack`.

The default style is `AutomaticArrangementViewStyle`, which resolves to split. Others: `SplitArrangementViewStyle`, `OverlayArrangementViewStyle`.

```swift
ArrangementView {
    PlayerControls()
} secondary: {
    VideoPlayer()
}
.arrangementViewStyle(.overlay)
```

```swift
ArrangementView {
    NowPlayingView()
} secondary: {
    LyricsView()
}
.arrangementViewStyle(.split.axes(.horizontal))
```

Verified companions: `arrangementViewStyle(_:)`, `axes(_:)`, `overlayArrangementEdge(_:)`, `splitArrangementFixedLayoutSize(horizontal:vertical:)`, `splitArrangementLayoutRatio(_:)`.

**Do not** place an arrangement view inside a `NavigationSplitView`, `List`, `ScrollView` or similar container — part of the content can become unreachable. Keep navigation containers *around* it, never within it.

## Bars on the vertical axis

On Duo the system moves navigation bars, toolbars and tab bars to the **side** of the display: on the outer display when closed, and in leading/trailing positions on the inner display. The exception is the **inner display in portrait**, which keeps standard horizontal bars.

This is automatic *only* for standard components. In SwiftUI that means `toolbar(content:)` on a `NavigationStack` or `NavigationSplitView`. In UIKit it means toolbar items on a view controller inside a navigation controller — **not** a hand-rolled bar built from `UIToolbar`, `UINavigationBar` or `UITabBar`.

Context-specific behaviour:

| Context | Behaviour |
| --- | --- |
| Inspectors | Always horizontal. |
| Split views | Horizontal for sidebar/content, vertical for detail. |
| Sheets, outer display | Vertical by default. Opt out with `toolbarVerticalBehavior(_:)` (SwiftUI) / `preferredVerticalBarBehavior` (UIKit). |
| Sheets, inner display | Horizontal for centered/leading placement, vertical for trailing. Control with `presentationPlacement(_:)` (SwiftUI) / `preferredPlacement` (UIKit). |

To detect vertical presentation in a custom view: the `toolbarVerticalEdge` environment value (SwiftUI) or the `verticalBarEdge` trait (UIKit).

For a hero or background image that should run under a vertical bar: `backgroundExtensionEffect()` (SwiftUI) / `UIBackgroundExtensionView` (UIKit).

### Ordering and overflow

Reserve the top of the vertical axis for primary navigation (Back, Close), then prominent actions (Done). A navigation controller adds Back automatically.

| Purpose | SwiftUI | UIKit |
| --- | --- | --- |
| Semantic grouping | `ToolbarItemPlacement` | item groups |
| Prominent trailing item (Done) | `topBarPinnedTrailing` placement | `pinnedTrailingGroup` |
| Custom Back/Close | `ToolbarItem` with `cancellationAction` | `leadingItemGroups` |
| Include/exclude from vertical layout | `axisBehavior(_:)` | `axisBehavior` |
| Overflow order | `visibilityPriority(_:)` | `visibilityPriority` |
| Force into overflow | `ToolbarOverflowMenu` | `additionalOverflowItems` |

Priority types: `ToolbarItemVisibilityPriority` (SwiftUI) / `UIBarButtonItemVisibilityPriority` (UIKit). Items overflow bottom-to-top by default.

**Give every toolbar item both an icon and a title.** The system uses the icon when vertical, prefers the icon when horizontal, and uses both in the overflow menu. An item with a title but **no icon is never presented vertically**, and neither is an item built from a custom view. This is the single most common reason a migrated toolbar looks broken on Duo.

## What to flag and fix

| Pattern | Problem | Fix |
| --- | --- | --- |
| `UIScreen.main.bounds`, cached sizes | Wrong after any fold, unfold or display transition | `GeometryReader`, scene/container bounds, size classes |
| `userInterfaceIdiom` / orientation checks | Duo is not in the list, and pose is not orientation | `horizontalSizeClass` / `verticalSizeClass` with automatic trait tracking |
| Fixed frames, hard-coded insets | Do not survive a resize | Size relative to the container; layout margins and safe area insets |
| `UIRequiresFullScreen`, orientation locks | Opts out of resizing entirely | Remove |
| Blanket `.ignoresSafeArea()` | Content slides under camera and fold regions | Scope it to specific edges |
| Hand-built tab bars and toolbars | Never presented vertically | `TabView`, `.toolbar`, `NavigationSplitView` |
| Interactive content centred on the fold | Sits across the hinge | Even column counts; `ReservedRegion` to move what the system does not |
| Toolbar items with no icon | Silently dropped from vertical bars | Add an icon alongside the title |
| `HStack`/`VStack`/`ZStack` of two major panes | Does not react to the fold | `ArrangementView`, split or overlay |
| Missing `#available` around 27.1 symbols | Fails to build or crashes below 27.1 | Gate and provide a fallback |

Scrolling content — feeds, lists, documents — is **expected** to cross the fold and needs no special handling. Shift existing elements out of the folding region rather than designing a separate layout per pose, and avoid dramatic rearrangement as the device folds: people lose track of controls that jump.

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

## Camera

With AVKit/AVFoundation an app can capture from the outer camera, the inner camera and the rear camera. Opening, closing or rotating the device can move the app to the other display, which means **the camera in use may end up facing the opposite direction mid-session**. Handle that transition rather than assuming a fixed facing. Apple's references: *Choosing a camera by the direction it faces*, and *Registering a camera capture accessory on iPhone Duo* for showing content on the outer display while capturing with the rear camera on an open device.

## Tooling

**Simulator and previews.** Xcode 27.1 beta ships an iPhone Duo Simulator runtime. Use **Device Hub** in Xcode to preview poses, and the Previews canvas **Display** override group to preview the alternative display. Known beta limitations: first Simulator launch can take several minutes, StandBy is unavailable, and most app extensions cannot be run or debugged in the Duo runtime.

**Linter.** If the project uses **duo-kit** (https://github.com/klavyeesir/duo-kit), run it first:

```bash
swift build -c release
.build/release/DuoLint <file-or-directory>...
```

Full usage: `DuoLint [--format text|sarif|github] <file-or-directory>...`. Keep `text` locally; `github` and `sarif` are for CI. Exit codes: 0 clean, 1 findings, 2 tool error — a non-zero exit on a dirty codebase is the expected result, not a broken tool.

Findings print as `file:line:col: warning: [rule-id] message`. The rule ids are `duo-screen-bounds`, `duo-odd-grid-columns`, `duo-ignores-safe-area` and `duo-manual-toolbar`. **The linter covers only those four patterns.** It has no rules for missing toolbar icons, missing `#available` gates, or stack-to-arrangement migrations, so read the layout code for the rest yourself.

If duo-kit is not present, skip this step — do not install it unasked and do not invent its output.

## Workflow for an audit request

1. Confirm the toolchain: Xcode 27.1 beta or later, and note that the app must be built with Xcode 27+ to use the full screen.
2. Run the linter if present; otherwise read the layout code directly.
3. Report findings grouped by the table above, with file and line.
4. Fix what is certain and SDK-independent first: screen bounds, idiom branches, fixed frames, full-screen opt-outs, blanket `.ignoresSafeArea()`, missing toolbar icons.
5. Propose the 27.1-specific changes — `ArrangementView`, `ReservedRegion`, bar axis and overflow control — each behind an availability gate, and each flagged as beta API.
6. For anything needing a symbol not listed in this file, leave `// TODO(duo):` and say what is blocked rather than guessing a name.
7. Tell the user to verify in the Duo simulator across closed, open and partially folded poses in both orientations, and state that you did not run it.

## Sources

Read on 2026-09-21:

- Apple HIG, *Designing for iPhone Duo* — https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo (published 2026-09-09)
- Apple, *Preparing your app for iPhone Duo* — https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo
- Apple, *ArrangementView* — https://developer.apple.com/documentation/swiftui/arrangementview
- Apple, *Xcode 27.1 Beta Release Notes* — https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes

Summarised in our own words; no Apple text is reproduced. Unofficial, not affiliated with Apple. **Re-verify every symbol when Xcode 27.1 reaches GA.**
