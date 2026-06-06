import Foundation

enum OverlayMode: String, CaseIterable, Identifiable {
    case clock      = "clock"
    case timer      = "timer"
    case stopwatch  = "stopwatch"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .clock:     return "Clock"
        case .timer:     return "Timer"
        case .stopwatch: return "Stopwatch"
        }
    }

    var icon: String {
        switch self {
        case .clock:     return "clock"
        case .timer:     return "timer"
        case .stopwatch: return "stopwatch"
        }
    }
}
