import SwiftDiagnostics

enum KeylineDiagnostic: String, DiagnosticMessage {
    case missingClosure
    case missingBody

    var message: String {
        switch self {
        case .missingClosure: "#Keyline requires a view closure"
        case .missingBody: "@Keylined requires a 'body' property"
        }
    }

    var diagnosticID: MessageID { MessageID(domain: "KeylineKit", id: rawValue) }
    var severity: DiagnosticSeverity { .error }
}
