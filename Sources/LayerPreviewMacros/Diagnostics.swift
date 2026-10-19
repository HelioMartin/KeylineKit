import SwiftDiagnostics

enum LayerPreviewDiagnostic: String, DiagnosticMessage {
    case missingClosure
    case missingBody

    var message: String {
        switch self {
        case .missingClosure: "#LayerPreview requires a view closure"
        case .missingBody: "@LayerPreviewInspectable requires a 'body' property"
        }
    }

    var diagnosticID: MessageID { MessageID(domain: "LayerPreview", id: rawValue) }
    var severity: DiagnosticSeverity { .error }
}
