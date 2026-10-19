import SwiftUI

/// A view whose `body` `#Keyline` can expand. Adopt it with
/// `@Keylined` rather than conforming manually.
@MainActor
public protocol KeylineInspectable {
    /// The view's `body` with every node instrumented for `#Keyline`.
    var _keylineBody: AnyView { get }
}
