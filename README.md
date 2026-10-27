# KitchenUI

The shared design language for Pantry and Grocery Deals.

**SwiftUI first.** Use SwiftUI's own components (List, Form, Label, LabeledContent,
ContentUnavailableView, bordered and glass button styles, Menu, Picker, searchable, swipe
actions, ShareLink, TipKit). They get Dynamic Type, VoiceOver, dark mode and Liquid Glass for
free. This package only adds what SwiftUI doesn't have:

- **Type:** Atkinson Hyperlegible Next (Braille Institute; OFL), scaling with Dynamic Type.
  Call `KitchenUI.registerFonts()` once at launch, then `.font(.app(.body))` or `.app(17, .semibold)`.
- **Color:** `Palette` tokens with light and dark values. One accent for now; an app can
  override it with `Palette.accent = …` before its first view loads.
- **Shape and space:** `Radius`, `Space`.
- **Components:** `FilterChip`, `ChipRow`, `Badge` (shape + label + tone, never color alone),
  `Card`, `SectionHeader`, `FlowLayout`, `AdaptiveStack`.
- **Appearance:** `.kitchenAppearance()` on the root view applies the Light/Dark and text size
  people choose in the app (both follow the iPhone by default); `AppearanceSettings()` is the
  Settings rows, wrapped in the app's own `Section`.
- **Onboarding:** `Onboarding(buddy:appName:tagline:pages:question:start:onFinish:)`, the first-run
  flow both apps use: a welcome, a tour of `TourPage`s, then a `UsageQuestion` about anonymous
  analytics. Everything but the question can be skipped from every screen; the question has two
  equal buttons and nothing chosen ahead of time. `start: .question` asks only the question
  (people who used the app before onboarding existed); `.tourOnly` replays the tour from
  Settings. No system permission prompts here: ask for those when someone uses the feature.
  The app saves the answer and sends nothing before a yes.
- **Dev menu:** `DevMenuSection { DevMenu(onboarding:analytics:resetAll:) { app sections } }` in
  Settings adds a "Developer" row on Debug, development-signed and TestFlight builds (never App
  Store builds, see `BuildKind`). Shared rows: show onboarding or the usage question, forget the
  answer, analytics status, device ID and flush, build details, reset everything. Apps add their
  own sections with `DevAction` rows.
- **Accessibility helpers:** `Announce.say(_:)`, `.lineLimitUnlessLarge(_:)`,
  `.hiddenWhenTextIsLarge()`.

Rules: status is never shown by color alone; every control is at least 44 points; text
must survive the largest accessibility sizes; colors meet WCAG AA in light and dark.

## Adopting it in an app (Grocery Deals is next)

1. In the app's `project.yml`: add `KitchenUI: path: <relative path to ~/Developer/KitchenUI>` under `packages` and `- package: KitchenUI` under the target's dependencies; run `xcodegen generate`.
2. Call `KitchenUI.registerFonts()` in the App's `init()` and add `.kitchenAppearance()` to the root view. Remove bundled fonts and `UIAppFonts` the package replaces.
3. Map the app's own Theme to `Palette` (as Pantry's `Theme.swift` does) so screens keep compiling, then replace hard-coded colors with tokens and remove any forced `.preferredColorScheme`.
4. Swap hand-built pieces for SwiftUI's own (ContentUnavailableView, bordered/prominent buttons, Label, LabeledContent) and the package's FilterChip/ChipRow/Badge/Card.
5. Check every screen at the largest accessibility text size and in dark mode; keep 44-point targets and VoiceOver labels.

Pantry's commits on its `app-scaffold` branch ("Design cleanup: adopt KitchenUI…", "Chat screens on KitchenUI…") are a worked example.
