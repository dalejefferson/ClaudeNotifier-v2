import Foundation

/// A named layout configuration that users can save and switch between.
struct LayoutTemplate: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var sections: [LayoutSection]
    let isBuiltIn: Bool
    let createdAt: Date
    var lastModified: Date

    init(
        id: UUID = UUID(),
        name: String,
        sections: [LayoutSection],
        isBuiltIn: Bool = false,
        createdAt: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.sections = sections
        self.isBuiltIn = isBuiltIn
        self.createdAt = createdAt
        self.lastModified = lastModified
    }

    /// Returns sections sorted by order, filtered to visible only.
    var visibleSections: [LayoutSection] {
        sections.filter { $0.isVisible }.sorted { $0.order < $1.order }
    }

    /// Returns all sections sorted by order (for edit mode).
    var sortedSections: [LayoutSection] {
        sections.sorted { $0.order < $1.order }
    }

    // MARK: - Built-in Templates

    static let defaultTemplate = LayoutTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Default",
        sections: [
            LayoutSection(type: .statusHeader, isVisible: true, order: 0),
            LayoutSection(type: .currentSession, isVisible: true, order: 1),
            LayoutSection(type: .todayStats, isVisible: true, order: 2),
            LayoutSection(type: .recentEvents, isVisible: true, order: 3)
        ],
        isBuiltIn: true
    )

    static let compactTemplate = LayoutTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Compact",
        sections: [
            LayoutSection(type: .statusHeader, isVisible: true, order: 0),
            LayoutSection(type: .currentSession, isVisible: true, order: 1),
            LayoutSection(type: .todayStats, isVisible: false, order: 2),
            LayoutSection(type: .recentEvents, isVisible: false, order: 3)
        ],
        isBuiltIn: true
    )

    static let focusedTemplate = LayoutTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Focused",
        sections: [
            LayoutSection(type: .statusHeader, isVisible: false, order: 0),
            LayoutSection(type: .currentSession, isVisible: true, order: 1),
            LayoutSection(type: .todayStats, isVisible: true, order: 2),
            LayoutSection(type: .recentEvents, isVisible: true, order: 3)
        ],
        isBuiltIn: true
    )

    static let builtInTemplates: [LayoutTemplate] = [
        .defaultTemplate,
        .compactTemplate,
        .focusedTemplate
    ]
}
