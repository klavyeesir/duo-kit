# iPhone Duo API reference

Every symbol on this page was read from developer.apple.com on **2026-09-21**, not recalled. All of them are **iOS 27.1+ and marked Beta**; spellings and signatures can change before GA. Gate each one behind `if #available(iOS 27.1, *)`.

If a symbol you need is not on this page, it is not verified. Say so and leave a `// TODO(duo):` marker — do not extrapolate a sibling name.

## Reserved regions

iOS models hardware intrusions as **reserved regions**, of two kinds:

- A **division** — the folding region splitting one large view into smaller usable areas. Active only when the device is *partially* open.
- An **occlusion** — hardware covering content. The **outer** front camera always occludes; the **inner** front camera occludes only while the camera is active.

A region can be **active or inactive**, so query it per layout pass rather than caching the result.

System components (alerts, context menus, sheets, split views) adapt on their own. Custom views do not:

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

The argument values for `kind:` and `options:` are **not recorded here**. Read them from the SDK before writing a call — do not guess an enum case.

## Arrangement views

`ArrangementView` (SwiftUI) / `UIArrangementViewController` (UIKit). A container for a **primary** and a **secondary** view that re-lays them out for the current size, size class and reserved regions.

```swift
nonisolated struct ArrangementView<Primary, Secondary> where Primary: View, Secondary: View
```

Two styles:

- **Split** — side by side when wider than tall, stacked when taller than wide. Adapts around the folding region. Use it when the code already has an `HStack` or `VStack`.
- **Overlay** — primary layered over secondary in z-order. When the device is *partially* open it splits instead: primary to the trailing/bottom side of the fold, secondary to the leading/top side. Use it when the code already has a `ZStack`.

Default style is `AutomaticArrangementViewStyle`, which resolves to split. Others: `SplitArrangementViewStyle`, `OverlayArrangementViewStyle`.

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

**Give every toolbar item both an icon and a title.** The system uses the icon when vertical, prefers the icon when horizontal, and uses both in the overflow menu. An item with a title but **no icon is never presented vertically**, and neither is an item built from a custom view. This is the most common reason a migrated toolbar looks broken on Duo.

## Camera

With AVKit/AVFoundation an app can capture from the outer camera, the inner camera and the rear camera. Opening, closing or rotating the device can move the app to the other display, which means **the camera in use may end up facing the opposite direction mid-session**. Handle that transition rather than assuming a fixed facing.

Apple's references: *Choosing a camera by the direction it faces*, and *Registering a camera capture accessory on iPhone Duo* for showing content on the outer display while capturing with the rear camera on an open device.

## Simulator and previews

Xcode 27.1 beta ships an iPhone Duo Simulator runtime. Use **Device Hub** in Xcode to preview poses, and the Previews canvas **Display** override group to preview the alternative display.

Known beta limitations: first Simulator launch can take several minutes, StandBy is unavailable, and most app extensions cannot be run or debugged in the Duo runtime.

## Sources

- Apple HIG, *Designing for iPhone Duo* — https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo
- Apple, *Preparing your app for iPhone Duo* — https://developer.apple.com/documentation/technologyoverviews/preparing-your-app-for-iphone-duo
- Apple, *ArrangementView* — https://developer.apple.com/documentation/swiftui/arrangementview
- Apple, *Xcode 27.1 Beta Release Notes* — https://developer.apple.com/documentation/xcode-release-notes/xcode-27_1-release-notes
