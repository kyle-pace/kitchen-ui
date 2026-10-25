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
- **Accessibility helpers:** `Announce.say(_:)`, `.lineLimitUnlessLarge(_:)`,
  `.hiddenWhenTextIsLarge()`.

Rules: status is never shown by color alone; every control is at least 44 points; text
must survive the largest accessibility sizes; colors meet WCAG AA in light and dark.
