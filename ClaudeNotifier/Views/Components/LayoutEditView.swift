import SwiftUI

struct LayoutEditView: View {
    @ObservedObject var layoutManager = LayoutManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var showingNewTemplateSheet = false
    @State private var newTemplateName = ""
    @State private var templateToRename: LayoutTemplate?
    @State private var renameText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Customize Layout")
                    .font(.headline)
                    .foregroundColor(themeManager.effectivePalette.textPrimary)

                Spacer()

                Button(action: { layoutManager.isEditMode = false }) {
                    Text("Done")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.effectivePalette.primary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            // Template Picker
            templatePicker

            Divider()

            // Section List
            sectionList

            Divider()

            // Template Actions
            templateActions
        }
        .padding(12)
        .background(themeManager.effectivePalette.surface)
        .cornerRadius(12)
        .sheet(isPresented: $showingNewTemplateSheet) {
            newTemplateSheet
        }
    }

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Template")
                .font(.caption)
                .foregroundColor(themeManager.effectivePalette.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(layoutManager.templates) { template in
                        TemplateChip(
                            template: template,
                            isSelected: layoutManager.activeTemplate.id == template.id,
                            onSelect: { layoutManager.setActiveTemplate(template) },
                            onDelete: { layoutManager.deleteTemplate(template) }
                        )
                    }
                }
            }
        }
    }

    private var sectionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sections")
                .font(.caption)
                .foregroundColor(themeManager.effectivePalette.textSecondary)

            Text("Drag to reorder, tap eye to show/hide")
                .font(.caption2)
                .foregroundColor(themeManager.effectivePalette.textTertiary)

            ForEach(layoutManager.activeTemplate.sortedSections) { section in
                SectionEditRow(section: section)
            }
        }
    }

    private var templateActions: some View {
        HStack(spacing: 12) {
            Button(action: { showingNewTemplateSheet = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("New Template")
                }
                .font(.caption)
                .foregroundColor(themeManager.effectivePalette.primary)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var newTemplateSheet: some View {
        VStack(spacing: 16) {
            Text("New Template")
                .font(.headline)

            TextField("Template Name", text: $newTemplateName)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Cancel") {
                    showingNewTemplateSheet = false
                    newTemplateName = ""
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Create") {
                    let _ = layoutManager.createTemplate(name: newTemplateName)
                    showingNewTemplateSheet = false
                    newTemplateName = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTemplateName.isEmpty)
            }
        }
        .padding()
        .frame(width: 280)
    }
}

// MARK: - Section Edit Row

struct SectionEditRow: View {
    let section: LayoutSection
    @ObservedObject var layoutManager = LayoutManager.shared
    @ObservedObject var themeManager = ThemeManager.shared
    @State private var isDragging = false
    @State private var isDropTarget = false

    var body: some View {
        HStack(spacing: 10) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 12))
                .foregroundColor(themeManager.effectivePalette.textTertiary)

            // Section icon
            Image(systemName: section.type.icon)
                .font(.caption)
                .foregroundColor(section.isVisible ? themeManager.effectivePalette.primary : themeManager.effectivePalette.textTertiary)
                .frame(width: 20)

            // Section name
            VStack(alignment: .leading, spacing: 2) {
                Text(section.type.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(section.isVisible ? themeManager.effectivePalette.textPrimary : themeManager.effectivePalette.textTertiary)

                Text(section.type.description)
                    .font(.caption2)
                    .foregroundColor(themeManager.effectivePalette.textTertiary)
                    .lineLimit(1)
            }

            Spacer()

            // Visibility toggle
            Button(action: {
                layoutManager.updateSectionVisibility(sectionType: section.type, isVisible: !section.isVisible)
            }) {
                Image(systemName: section.isVisible ? "eye.fill" : "eye.slash")
                    .font(.caption)
                    .foregroundColor(section.isVisible ? themeManager.effectivePalette.success : themeManager.effectivePalette.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDropTarget ? themeManager.effectivePalette.primary.opacity(0.1) : themeManager.effectivePalette.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isDropTarget ? themeManager.effectivePalette.primary : Color.clear, lineWidth: 1)
        )
        .opacity(isDragging ? 0.5 : 1.0)
        .onDrag {
            isDragging = true
            return NSItemProvider(object: section.type.rawValue as NSString)
        }
        .onDrop(of: [.text], isTargeted: $isDropTarget) { providers in
            handleDrop(providers: providers)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let typeString = object as? String,
                  let sourceType = LayoutSectionType(rawValue: typeString) else { return }

            DispatchQueue.main.async {
                isDragging = false

                let sortedSections = layoutManager.activeTemplate.sortedSections
                guard let sourceIndex = sortedSections.firstIndex(where: { $0.type == sourceType }),
                      let destIndex = sortedSections.firstIndex(where: { $0.type == section.type }),
                      sourceIndex != destIndex else { return }

                let source = IndexSet(integer: sourceIndex)
                let destination = sourceIndex < destIndex ? destIndex + 1 : destIndex
                layoutManager.reorderSections(from: source, to: destination)
            }
        }
        return true
    }
}

// MARK: - Template Chip

struct TemplateChip: View {
    let template: LayoutTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void

    @ObservedObject var themeManager = ThemeManager.shared

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                if template.isBuiltIn {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8))
                }
                Text(template.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? themeManager.effectivePalette.primary : themeManager.effectivePalette.background)
            )
            .foregroundColor(isSelected ? .white : themeManager.effectivePalette.textPrimary)
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !template.isBuiltIn {
                Button("Delete", role: .destructive, action: onDelete)
            }
        }
    }
}
