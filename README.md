<picture>
  <source media="(prefers-color-scheme: dark)" srcset=".github/assets/keylinekit-banner-dark.png">
  <img src=".github/assets/keylinekit-banner-light.png" alt="KeylineKit: measured layout annotations for SwiftUI previews">
</picture>

<p align="center">
  <a href="#installation"><img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6"></a>
  <a href="#installation"><img src="https://img.shields.io/badge/Apple-iOS_16%2B_%7C_macOS_13%2B_%7C_watchOS_9%2B-222222?logo=apple" alt="iOS 16+, macOS 13+ and watchOS 9+"></a>
  <a href="#installation"><img src="https://img.shields.io/badge/Swift_Package_Manager-compatible-4BC51D" alt="Swift Package Manager compatible"></a>
  <a href="#license"><img src="https://img.shields.io/badge/License-MIT-blue" alt="MIT license"></a>
</p>

# KeylineKit

**See the layout SwiftUI actually renders.**

Is that padding 16 or 20? Where does the safe area end? Why is there a gap
between those two rows? You usually find out by adding `.border(.red)`,
squinting at the Canvas and removing it again.

KeylineKit draws the answer on top of your preview. Wrap a view in
`#Keyline` and every layer gets its name, its padding and the spacing
between its siblings, **measured in points** from the rendered layout. It
can also show sizes, corner radii and the device safe area.

<p align="center">
  <a href="https://heliomartin.github.io/KeylineKit/"><picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/keylinekit-website-dark.png">
    <img src=".github/assets/keylinekit-website-light.png" width="123" alt="KeylineKit website">
  </picture></a>
</p>

<p align="center">
  <a href="#features">🌟 Features</a> ·
  <a href="#why-keylinekit">🤔 Why KeylineKit?</a> ·
  <a href="#installation">📲 Installation</a> ·
  <a href="#usage">🐒 Usage</a> ·
  <a href="#annotations">🎨 Annotations</a> ·
  <a href="#custom-views">🧩 Custom views</a> ·
  <a href="#how-it-works">⚙️ How it works</a> ·
  <a href="#contributing">❤️ Contributing</a>
</p>

<table>
  <tr>
    <td align="center" width="33%">
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset=".github/assets/screenshots/default-dark.png">
        <img src=".github/assets/screenshots/default-light.png" alt="A SwiftUI account screen with every layer named, padding bands in orange and stack spacing in purple">
      </picture>
      <br><sub><b>Layers, padding and spacing</b></sub>
    </td>
    <td align="center" width="33%">
      <img src=".github/assets/screenshots/safe-area.png" alt="The same screen with the top and bottom safe-area insets in orange and the safe area outlined in green">
      <br><sub><b>Safe area</b></sub>
    </td>
    <td align="center" width="33%">
      <img src=".github/assets/screenshots/corners-sizes.png" alt="A profile card with width and height dimension lines and its corner radius">
      <br><sub><b>Corners and sizes</b></sub>
    </td>
  </tr>
</table>

<a name="features"></a>

## 🌟 Features

- 📏 **Measured, not guessed:** padding, spacing and sizes come from the rendered layout, in points.
- 🏷 **Every layer named:** each view's type next to its bounds, nested containers included.
- 📱 **Safe area at a glance:** device insets, the safe area and, on iOS 27.1, the reserved regions that cover content, such as camera housings.
- ⭕️ **Corner radii:** the arc and value of `cornerRadius:` and `.cornerRadius(_:)`.
- 🧩 **Your own views too:** `@Keylined` opens a custom view's `body` to the overlay.
- 🙈 **No label pile-ups:** all labels are laid out together, so they never cover each other.
- 🌗 **Light and dark:** a palette tuned for both.
- 🪶 **Preview-only:** `#Keyline` lives in your previews; your views render exactly as before everywhere else.

<a name="why-keylinekit"></a>

## 🤔 Why not just use `.border()`?

You can! A border or a background is often the quickest way to check one
view. KeylineKit is for when you want the whole picture, with numbers:

| You want to… | Usually | With KeylineKit |
| --- | --- | --- |
| 🔲 See a view's bounds | Add `.border(.red)` to each view, then remove it | Every layer is outlined and named |
| 📐 Check padding | Read the code and guess what `default` means | Each edge is measured: `16 · default` |
| ↕️ Check stack spacing | Add backgrounds or run the View Debugger | The gap between siblings is filled and measured |
| 📱 Check the safe area | Print `safeAreaInsets` | Insets and the safe area are drawn on the Canvas |
| ⚡️ Stay in Previews | The View Debugger needs a running app | Works in `#Preview`, no app launch needed |

<a name="installation"></a>

## 📲 Installation

Build with **Xcode 16 or later** (Swift 6). Your app can target
**iOS 16+, macOS 13+ or watchOS 9+**.

| Capability | Minimum |
| --- | --- |
| Layers, padding, spacing, sizes and corners | iOS 16 / macOS 13 / watchOS 9 |
| Safe-area insets | iOS 16 |
| Reserved regions that cover content | iOS 27.1 SDK and runtime |

In Xcode, choose **File › Add Package Dependencies…** and enter the
repository URL. Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/HelioMartin/KeylineKit.git", branch: "main"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "KeylineKit", package: "KeylineKit"),
    ]),
]
```

KeylineKit depends only on [swift-syntax](https://github.com/swiftlang/swift-syntax)
(`600.0.0..<700.0.0`), which its macros need.

<a name="usage"></a>

## 🐒 Usage

Three steps:

### 1️⃣ Import

```swift
import KeylineKit
```

### 2️⃣ Wrap your preview

```swift
#Preview {
    #Keyline {
        VStack(spacing: 16) {
            ProfileView()
        }
        .padding(24)
    }
}
```

### 3️⃣ Read the Canvas

Every layer gets its name and outline. Padding appears as orange bands with
a value on each edge, and the gaps between stack children appear in purple.

That's it! There is nothing to remove before shipping: `#Keyline` only
runs where you write it.

> 💡 Values are measured, so they show what SwiftUI applies. When the
> source says something different, the declared value is shown next to it:
> `.padding()` reads `16 · default`, and `VStack(spacing: Theme.spacing)`
> reads `12 · Theme.spacing`.

<a name="annotations"></a>

## 🎨 Choose your annotations

With no arguments you get `.layers`, `.padding` and `.spacing`. Pass the ones
you want instead:

```swift
#Keyline(.padding, .corners) { ProfileView() }
#Keyline(.safeArea, .layers) { AccountScreen() }
#Keyline(.layers, showContainerLines: false) { ProfileView() }
```

| Annotation | Draws | Color |
| --- | --- | --- |
| `.layers` | The name of each layer next to its bounds | ![#1447E6](https://img.shields.io/badge/%231447E6-1447E6?style=flat-square) |
| `.padding` | A band per `.padding(...)` call, a value per edge and the content outline | ![#CA3500](https://img.shields.io/badge/%23CA3500-CA3500?style=flat-square) ![#008236](https://img.shields.io/badge/%23008236-008236?style=flat-square) |
| `.spacing` | The gap between siblings of a `VStack` or `HStack` | ![#8200DB](https://img.shields.io/badge/%238200DB-8200DB?style=flat-square) |
| `.size` | Width and height dimension lines for each layer | ![#314158](https://img.shields.io/badge/%23314158-314158?style=flat-square) |
| `.corners` | The arc and value of each corner radius | ![#C6005C](https://img.shields.io/badge/%23C6005C-C6005C?style=flat-square) |
| `.safeArea` | Device insets, the safe area and reserved regions | ![#CA3500](https://img.shields.io/badge/%23CA3500-CA3500?style=flat-square) ![#008236](https://img.shields.io/badge/%23008236-008236?style=flat-square) ![#8200DB](https://img.shields.io/badge/%238200DB-8200DB?style=flat-square) |
| `.none` | Nothing; outlines still follow `showContainerLines` | |

Layer outlines are on by default. Turn them off with `showContainerLines: false`.

<a name="custom-views"></a>

## 🧩 Look inside your own views

`#Keyline` only sees the code inside its own closure, so a custom view like
`ProfileView()` shows up as a single layer. Add `@Keylined` to the type and
the overlay also draws what its `body` declares:

```swift
@Keylined
struct ProfileView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
            Text("Taylor Morgan")
        }
        .padding(24)
    }
}
```

When a view and the root of its `body` share the same frame, they share a
label: `ProfileView › VStack`.

<details>
<summary>🔍 What does the macro instrument?</summary>

- Any capitalized initializer (`VStack`, `ScrollView`, `NavigationStack`,
  `CustomCard`…) is entered, including closures such as `label:`,
  `header:` and `footer:`.
- The branches of `if`, `switch` and `#if` are entered.
- `ForEach` and `Group` without modifiers are transparent: their children
  count as siblings of the enclosing stack.
- Closures that are actions or don't build views are left alone:
  `Button("Save") { save() }`, `TextField`, `Canvas`, `Chart`, `Map` and
  `Table`. `Button(action:) { … }` and `Button { … } label: { … }` still
  instrument their label.
- Literals that Xcode rewrites for live editing (`__designTimeInteger(…)`)
  are shown with their value.

</details>

<details>
<summary>⚠️ Current limitations</summary>

- `.corners` reads the radius from modifiers, not from a root shape such as
  `RoundedRectangle(cornerRadius:)` used directly as a view.
- A custom view with modifiers (`ProfileView().padding()`) is drawn as a
  single layer, even when it uses `@Keylined`.
- Reserved regions need the iOS 27.1 SDK at build time and iOS 27.1 at runtime.

</details>

<a name="how-it-works"></a>

## ⚙️ How it works

```mermaid
flowchart LR
    A["#35;Keyline { … }"] -->|compile time| B["Each view wrapped in a node,<br/>probes around .padding"]
    B -->|runtime| C["onGeometryChange<br/>reports frames"]
    C --> D["Annotation layout:<br/>insets, gaps, labels"]
    D --> E["One Canvas overlay"]
```

1. **Macro** (`Sources/KeylineKitMacros`): rewrites the closure at compile
   time, wrapping each view and inserting probes before and after every
   `.padding(...)` and after every modifier with a corner radius.
2. **Measurement** (`Sources/KeylineKit/Measurement`): each node and probe
   reports its global frame with `onGeometryChange`. This also works inside
   `NavigationStack` and `ScrollView`.
3. **Drawing** (`Sources/KeylineKit/Rendering`): a pure, tested layout step
   turns the frames into regions, dimension lines and non-overlapping labels,
   and a single `Canvas` draws them.

Types prefixed with `_` are public only because the expanded code uses them;
they are hidden from the documentation.

### 📱 Try the demo

`Examples/KeylineDemo/KeylineDemo.xcodeproj` has a `#Preview` for each
annotation. The iOS app can also show the annotated screens at runtime:

```sh
xcrun simctl launch booted com.keylinekit.demo.ios -KeylineOverlay safeArea
```

Modes: `defaults`, `safeArea` and `details`.

<a name="contributing"></a>

## ❤️ Contributing

Found a layout KeylineKit draws wrong? I'd love to see it.

- Open an issue with a small view that reproduces it.
- Suggest an improvement or send a pull request.
- Add a test for a fix: macro expansions live in `Tests/KeylineKitMacrosTests`
  and layout logic in `Tests/KeylineKitTests`.

Run the tests with:

```sh
swift test
```

> 📣 If `xcode-select` points to the Command Line Tools, SwiftPM can't find
> the SDK's SwiftUI macros (`@State`, `@Entry`). Use Xcode's toolchain:
> `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test`.

## 👨🏻‍💻 Author

Made by [Helio Martín](https://github.com/HelioMartin).

<a name="license"></a>

## 👮🏻 License

KeylineKit is available under the [MIT license](LICENSE).
