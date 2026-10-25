// swift-tools-version: 6.2
import PackageDescription

// The shared design language for the kitchen apps (Pantry and Grocery Deals): Atkinson
// Hyperlegible, light and dark colors, and the few components SwiftUI doesn't have.
// Everything else should be SwiftUI's own components.
let package = Package(
    name: "KitchenUI",
    platforms: [.iOS(.v26)],
    products: [.library(name: "KitchenUI", targets: ["KitchenUI"])],
    targets: [
        .target(name: "KitchenUI", resources: [.copy("Resources/Fonts")]),
    ]
)
