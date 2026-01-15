import SwiftUI
import Combine

/// Storage container for layout persistence.
struct LayoutStoreData: Codable {
    var templates: [LayoutTemplate]
    var activeTemplateId: UUID
    var metadata: LayoutMetadata

    init(
        templates: [LayoutTemplate] = LayoutTemplate.builtInTemplates,
        activeTemplateId: UUID = LayoutTemplate.defaultTemplate.id,
        metadata: LayoutMetadata = LayoutMetadata()
    ) {
        self.templates = templates
        self.activeTemplateId = activeTemplateId
        self.metadata = metadata
    }
}

struct LayoutMetadata: Codable {
    let version: Int
    var lastModified: Date

    init(version: Int = 1, lastModified: Date = Date()) {
        self.version = version
        self.lastModified = lastModified
    }
}

@MainActor
final class LayoutManager: ObservableObject {
    static let shared = LayoutManager()

    // MARK: - Published Properties

    @Published private(set) var templates: [LayoutTemplate] = []
    @Published private(set) var activeTemplate: LayoutTemplate = .defaultTemplate
    @Published var isEditMode: Bool = false

    // MARK: - Persistence

    @AppStorage("activeLayoutTemplateId") private var storedTemplateId: String = ""

    private let persistencePath: String
    private var persistTimer: Timer?
    private var needsPersist = false
    private let batchInterval: TimeInterval = 2.0

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Initialization

    private init(persistencePath: String? = nil) {
        self.persistencePath = persistencePath ?? Self.defaultPersistencePath
        load()
    }

    private static var defaultPersistencePath: String {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        return homeDirectory.appendingPathComponent(".claude-notifier-layouts.json").path
    }

    // MARK: - Template Management

    func setActiveTemplate(_ template: LayoutTemplate) {
        guard let existingTemplate = templates.first(where: { $0.id == template.id }) else { return }
        activeTemplate = existingTemplate
        storedTemplateId = template.id.uuidString
        schedulePersist()
    }

    func createTemplate(name: String, basedOn template: LayoutTemplate? = nil) -> LayoutTemplate {
        let baseTemplate = template ?? activeTemplate
        let newTemplate = LayoutTemplate(
            name: name,
            sections: baseTemplate.sections.map { section in
                LayoutSection(type: section.type, isVisible: section.isVisible, order: section.order)
            },
            isBuiltIn: false
        )
        templates.append(newTemplate)
        activeTemplate = newTemplate
        storedTemplateId = newTemplate.id.uuidString
        schedulePersist()
        return newTemplate
    }

    func deleteTemplate(_ template: LayoutTemplate) {
        guard !template.isBuiltIn else { return }
        templates.removeAll { $0.id == template.id }
        if activeTemplate.id == template.id {
            activeTemplate = templates.first ?? .defaultTemplate
            storedTemplateId = activeTemplate.id.uuidString
        }
        schedulePersist()
    }

    func renameTemplate(_ template: LayoutTemplate, to newName: String) {
        guard !template.isBuiltIn else { return }
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].name = newName
            templates[index].lastModified = Date()
            if activeTemplate.id == template.id {
                activeTemplate = templates[index]
            }
            schedulePersist()
        }
    }

    // MARK: - Section Management

    func updateSectionVisibility(sectionType: LayoutSectionType, isVisible: Bool) {
        guard let templateIndex = templates.firstIndex(where: { $0.id == activeTemplate.id }) else { return }
        if let sectionIndex = templates[templateIndex].sections.firstIndex(where: { $0.type == sectionType }) {
            templates[templateIndex].sections[sectionIndex].isVisible = isVisible
            templates[templateIndex].lastModified = Date()
            activeTemplate = templates[templateIndex]
            schedulePersist()
        }
    }

    func reorderSections(from source: IndexSet, to destination: Int) {
        guard let templateIndex = templates.firstIndex(where: { $0.id == activeTemplate.id }) else { return }

        var sortedSections = templates[templateIndex].sortedSections
        sortedSections.move(fromOffsets: source, toOffset: destination)

        // Update order values
        for (index, section) in sortedSections.enumerated() {
            if let sectionIndex = templates[templateIndex].sections.firstIndex(where: { $0.id == section.id }) {
                templates[templateIndex].sections[sectionIndex].order = index
            }
        }

        templates[templateIndex].lastModified = Date()
        activeTemplate = templates[templateIndex]
        schedulePersist()
    }

    func moveSectionUp(_ section: LayoutSection) {
        let sortedSections = activeTemplate.sortedSections
        guard let currentIndex = sortedSections.firstIndex(where: { $0.id == section.id }),
              currentIndex > 0 else { return }

        let source = IndexSet(integer: currentIndex)
        reorderSections(from: source, to: currentIndex - 1)
    }

    func moveSectionDown(_ section: LayoutSection) {
        let sortedSections = activeTemplate.sortedSections
        guard let currentIndex = sortedSections.firstIndex(where: { $0.id == section.id }),
              currentIndex < sortedSections.count - 1 else { return }

        let source = IndexSet(integer: currentIndex)
        reorderSections(from: source, to: currentIndex + 2)
    }

    // MARK: - Persistence

    private func schedulePersist() {
        needsPersist = true
        guard persistTimer == nil else { return }
        persistTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.flush()
            }
        }
    }

    func flush() {
        guard needsPersist else { return }
        save()
        needsPersist = false
        persistTimer?.invalidate()
        persistTimer = nil
    }

    private func save() {
        do {
            let data = LayoutStoreData(
                templates: templates,
                activeTemplateId: activeTemplate.id
            )
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: URL(fileURLWithPath: persistencePath))
        } catch {
            print("LayoutManager: Failed to save layouts: \(error.localizedDescription)")
        }
    }

    private func load() {
        let fileURL = URL(fileURLWithPath: persistencePath)

        if FileManager.default.fileExists(atPath: persistencePath) {
            do {
                let jsonData = try Data(contentsOf: fileURL)
                let data = try decoder.decode(LayoutStoreData.self, from: jsonData)

                // Merge built-in templates with user templates
                var loadedTemplates = LayoutTemplate.builtInTemplates
                loadedTemplates.append(contentsOf: data.templates.filter { !$0.isBuiltIn })
                templates = loadedTemplates

                // Restore active template
                if let active = templates.first(where: { $0.id == data.activeTemplateId }) {
                    activeTemplate = active
                }
            } catch {
                print("LayoutManager: Failed to load layouts: \(error.localizedDescription)")
                templates = LayoutTemplate.builtInTemplates
                activeTemplate = .defaultTemplate
            }
        } else {
            templates = LayoutTemplate.builtInTemplates
            activeTemplate = .defaultTemplate
        }

        storedTemplateId = activeTemplate.id.uuidString
    }
}
