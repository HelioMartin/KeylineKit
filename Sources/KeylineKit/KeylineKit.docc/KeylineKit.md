# ``KeylineKit``

Measured layout annotations for SwiftUI previews.

## Overview

KeylineKit draws the layout SwiftUI actually renders on top of your
previews. Wrap a preview in `#Keyline` and
every layer gets its name, its padding and the spacing between its
siblings, measured in points from the rendered layout. It can also show
sizes, corner radii and the device safe area.

```swift
import KeylineKit

#Preview {
    #Keyline {
        VStack(spacing: 16) {
            ProfileView()
        }
        .padding(24)
    }
}
```

@Image(source: "keyline-default.png", alt: "An account screen with every layer named, padding bands in orange and the gaps between stack children in purple")

Values are measured, so they show what SwiftUI applies. When the source
says something different, the declared value is shown next to it:
`.padding()` reads `16 · default`, and `VStack(spacing: Theme.spacing)`
reads `12 · Theme.spacing`.

`#Keyline` only runs where you write it, so there is nothing to remove
before shipping.

### Choose what to draw

With no arguments, `#Keyline` draws `.layers`, `.padding` and `.spacing`.
Pass the ``KeylineAnnotation`` values you want instead:

```swift
#Keyline(.padding, .corners) { ProfileView() }
#Keyline(.safeArea, .layers) { AccountScreen() }
#Keyline(.layers, showContainerLines: false) { ProfileView() }
```

### Look inside your own views

`#Keyline` only sees the code inside its own closure, so a custom view
such as `ProfileView()` shows up as a single layer. Add `@Keylined` to
the type and the overlay also draws what its `body` declares:

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

### Use your own colors

Pass ``KeylineColors`` to `keylineColors(_:)` on any view that contains a
`#Keyline`. Set only the colors you want to change; the rest keep the
default palette:

```swift
#Keyline(.padding, .safeArea) {
    AccountScreen()
}
.keylineColors(KeylineColors(padding: .red, content: .blue))
```

## Topics

### Annotating previews

- ``Keyline(_:showContainerLines:body:)``
- ``KeylineAnnotation``

### Custom views

- ``Keylined()``
- ``KeylineInspectable``

### Colors

- ``KeylineColors``
