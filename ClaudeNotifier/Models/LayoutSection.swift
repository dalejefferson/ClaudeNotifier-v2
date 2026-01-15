import Foundation

/// Defines the types of customizable sections in the menu bar.
enum LayoutSectionType: String, Codable, CaseIterable, Identifiable {
    case statusHeader = "status_header"
    case currentSession = "current_session"
    case todayStats = "today_stats"
    case recentEvents = "recent_events"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .statusHeader: return "Status Header"
        case .currentSession: return "Current Session"
        case .todayStats: return "Today's Stats"
        case .recentEvents: return "Recent Events"
        }
    }

    var icon: String {
        switch self {
        case .statusHeader: return "antenna.radiowaves.left.and.right"
        case .currentSession: return "cpu"
        case .todayStats: return "chart.bar.fill"
        case .recentEvents: return "clock.fill"
        }
    }

    var description: String {
        switch self {
        case .statusHeader: return "Listening indicator and agent status"
        case .currentSession: return "Model, tokens, usage bars, active agents"
        case .todayStats: return "Task count, duration badges, activity chart"
        case .recentEvents: return "Last 2 completed events"
        }
    }
}

/// Represents a single section's configuration in the layout.
struct LayoutSection: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let type: LayoutSectionType
    var isVisible: Bool
    var order: Int

    init(id: UUID = UUID(), type: LayoutSectionType, isVisible: Bool = true, order: Int) {
        self.id = id
        self.type = type
        self.isVisible = isVisible
        self.order = order
    }
}
