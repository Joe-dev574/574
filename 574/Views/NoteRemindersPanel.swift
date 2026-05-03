//
//  NoteRemindersPanel.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  Unified "Links" inspector panel.
//  Phase 1: full Reminders CRUD + Calendar read/create/delete.
//  A segmented picker at the top switches between the two tabs.
//

import SwiftUI
import EventKit
import SwiftData

// MARK: - LinksTab

private enum LinksTab: Hashable {
    case reminders
    case calendar
}

// MARK: - NoteRemindersPanel

/// The inspector panel shown at the trailing edge of ``NoteDetailView``.
///
/// A segmented control switches between **Reminders** (full CRUD) and
/// **Calendar** (create, read, delete) tabs.  Both interact with the system
/// apps via ``EventKitManager`` and persist links in SwiftData.
struct NoteRemindersPanel: View {

    // MARK: - Properties

    @Bindable var note: Note

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Tab

    @State private var activeTab: LinksTab = .reminders

    // MARK: - Reminder State

    @State private var reminders: [EKReminder] = []
    @State private var reminderLoadState: PanelLoadState = .idle
    @State private var addReminderTitle: String = ""
    @State private var addReminderDueDate: Date = Self.oneHourFromNow
    @State private var showReminderDueDatePicker: Bool = false
    @State private var isSubmittingReminder: Bool = false
    @FocusState private var reminderFieldFocused: Bool

    // MARK: - Calendar State

    @State private var events: [EKEvent] = []
    @State private var eventLoadState: PanelLoadState = .idle
    @State private var addEventTitle: String = ""
    @State private var addEventStart: Date = Self.oneHourFromNow
    @State private var addEventEnd: Date = Self.twoHoursFromNow
    @State private var showEventDatePickers: Bool = false
    @State private var isSubmittingEvent: Bool = false
    @FocusState private var eventFieldFocused: Bool

    private let manager = EventKitManager.shared

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            Divider()
            contentArea
            Divider()
            addSection
        }
        .background(Color(.controlBackgroundColor))
        .task { await loadAll() }
    }

    // MARK: - Panel Header

    private var panelHeader: some View {
        VStack(spacing: 6) {
            Picker("Links", selection: $activeTab) {
                Label("Reminders", systemImage: "bell").tag(LinksTab.reminders)
                Label("Calendar",  systemImage: "calendar").tag(LinksTab.calendar)
            }
            .pickerStyle(.segmented)

            HStack(spacing: 6) {
                badgeView
                Spacer()
                refreshControl
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var badgeView: some View {
        if activeTab == .reminders {
            HStack(spacing: 4) {
                Image(systemName: "bell.fill").font(.caption).foregroundStyle(.orange)
                let pending = reminders.filter { !$0.isCompleted }.count
                if reminderLoadState == .loaded, pending > 0 {
                    Text("\(pending)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color.orange).clipShape(Capsule())
                        .accessibilityLabel("\(pending) pending reminder\(pending == 1 ? "" : "s")")
                }
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "calendar").font(.caption).foregroundStyle(.blue)
                let upcoming = events.filter { $0.startDate >= Date() }.count
                if eventLoadState == .loaded, upcoming > 0 {
                    Text("\(upcoming)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Color.blue).clipShape(Capsule())
                        .accessibilityLabel("\(upcoming) upcoming event\(upcoming == 1 ? "" : "s")")
                }
            }
        }
    }

    @ViewBuilder
    private var refreshControl: some View {
        let isLoading = activeTab == .reminders
            ? reminderLoadState == .loading
            : eventLoadState == .loading
        if isLoading {
            ProgressView().controlSize(.mini)
        } else {
            Button { Task { await loadAll() } } label: {
                Image(systemName: "arrow.clockwise").font(.caption).foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .help("Refresh")
            .accessibilityLabel("Refresh")
        }
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        switch activeTab {
        case .reminders:
            switch reminderLoadState {
            case .idle, .loading: centredSpinner
            case .denied:         permissionDeniedView(.reminders)
            case .error(let m):   loadErrorView(m, tab: .reminders)
            case .loaded:
                if reminders.isEmpty { emptyStateView(.reminders) }
                else { reminderList }
            }
        case .calendar:
            switch eventLoadState {
            case .idle, .loading: centredSpinner
            case .denied:         permissionDeniedView(.calendar)
            case .error(let m):   loadErrorView(m, tab: .calendar)
            case .loaded:
                if events.isEmpty { emptyStateView(.calendar) }
                else { eventList }
            }
        }
    }

    // MARK: - Shared State Views

    private var centredSpinner: some View {
        HStack { Spacer(); ProgressView().controlSize(.small); Spacer() }
            .frame(minHeight: 100)
    }

    private func emptyStateView(_ tab: LinksTab) -> some View {
        VStack(spacing: 8) {
            Image(systemName: tab == .reminders ? "bell.slash" : "calendar.badge.exclamationmark")
                .font(.system(size: 30)).foregroundStyle(.tertiary)
            Text(tab == .reminders ? "No linked reminders" : "No linked events")
                .font(.subheadline).foregroundStyle(.secondary)
            Text(tab == .reminders
                 ? "Use the field below to attach action items to this note."
                 : "Use the field below to schedule events for this note.")
                .font(.caption).foregroundStyle(.tertiary).multilineTextAlignment(.center)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    private func permissionDeniedView(_ tab: LinksTab) -> some View {
        VStack(spacing: 10) {
            Image(systemName: tab == .reminders ? "bell.slash.circle.fill" : "calendar.badge.exclamationmark")
                .font(.system(size: 34))
                .foregroundStyle(tab == .reminders ? Color.orange : Color.blue)
            Text(tab == .reminders ? "Reminders Access Required" : "Calendar Access Required")
                .font(.subheadline.weight(.semibold))
            Text(tab == .reminders
                 ? "IndieGrind needs full Reminders access to create and sync action items."
                 : "IndieGrind needs full Calendar access to create and sync events.")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            #if os(macOS)
            Button("Open System Settings") {
                let url = tab == .reminders
                    ? "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders"
                    : "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
                NSWorkspace.shared.open(URL(string: url)!)
            }
            .buttonStyle(.borderedProminent)
            .tint(tab == .reminders ? .orange : .blue)
            .controlSize(.small)
            #endif
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 140)
    }

    private func loadErrorView(_ message: String, tab: LinksTab) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red)
            Text(message).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("Retry") { Task { await loadAll() } }.buttonStyle(.bordered).controlSize(.small)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 100)
    }

    // MARK: - Reminder List

    private var reminderList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(reminders, id: \.calendarItemIdentifier) { reminder in
                    ReminderRow(
                        reminder: reminder,
                        onToggle: { Task { await toggleReminder(reminder) } },
                        onDelete: { Task { await deleteReminder(reminder) } }
                    )
                    if reminder.calendarItemIdentifier != reminders.last?.calendarItemIdentifier {
                        Divider().padding(.leading, 38)
                    }
                }
            }
        }
        .frame(maxHeight: 340)
    }

    // MARK: - Event List

    private var eventList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(events, id: \.calendarItemIdentifier) { event in
                    EventRow(event: event, onDelete: { Task { await deleteCalendarEvent(event) } })
                    if event.calendarItemIdentifier != events.last?.calendarItemIdentifier {
                        Divider().padding(.leading, 38)
                    }
                }
            }
        }
        .frame(maxHeight: 340)
    }

    // MARK: - Add Section

    @ViewBuilder
    private var addSection: some View {
        switch activeTab {
        case .reminders: addReminderSection
        case .calendar:  addEventSection
        }
    }

    private var addReminderSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.callout)
                    .foregroundStyle(addReminderTitle.isEmpty ? Color.secondary : Color.orange)
                    .animation(.easeOut(duration: 0.1), value: addReminderTitle.isEmpty)

                TextField("Add a reminder…", text: $addReminderTitle)
                    .textFieldStyle(.plain).font(.callout)
                    .focused($reminderFieldFocused)
                    .accessibilityLabel("New reminder title")
                    .onSubmit { Task { await submitReminder() } }

                if isSubmittingReminder {
                    ProgressView().controlSize(.mini)
                } else if !addReminderTitle.isEmpty {
                    Button { Task { await submitReminder() } } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.title3).foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain).help("Add reminder (Return)").accessibilityLabel("Add reminder")
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, addReminderTitle.isEmpty ? 10 : 4)

            if !addReminderTitle.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showReminderDueDatePicker.toggle()
                            if !showReminderDueDatePicker { addReminderDueDate = Self.oneHourFromNow }
                        }
                    } label: {
                        Label(
                            showReminderDueDatePicker ? "Remove due date" : "Set due date",
                            systemImage: showReminderDueDatePicker ? "calendar.badge.minus" : "calendar.badge.plus"
                        )
                        .font(.caption)
                        .foregroundStyle(showReminderDueDatePicker ? Color.secondary : Color.orange)
                    }
                    .buttonStyle(.plain).padding(.leading, 12)

                    if showReminderDueDatePicker {
                        DatePicker("Due date", selection: $addReminderDueDate, in: Date()...,
                                   displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(.compact).labelsHidden()
                            .padding(.horizontal, 12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .background(Color(.windowBackgroundColor).opacity(0.5))
    }

    private var addEventSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .font(.callout)
                    .foregroundStyle(addEventTitle.isEmpty ? Color.secondary : Color.blue)
                    .animation(.easeOut(duration: 0.1), value: addEventTitle.isEmpty)

                TextField("Add an event…", text: $addEventTitle)
                    .textFieldStyle(.plain).font(.callout)
                    .focused($eventFieldFocused)
                    .accessibilityLabel("New event title")
                    .onSubmit { Task { await submitEvent() } }

                if isSubmittingEvent {
                    ProgressView().controlSize(.mini)
                } else if !addEventTitle.isEmpty {
                    Button { Task { await submitEvent() } } label: {
                        Image(systemName: "arrow.up.circle.fill").font(.title3).foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain).help("Add event (Return)").accessibilityLabel("Add event")
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, addEventTitle.isEmpty ? 10 : 4)

            if !addEventTitle.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showEventDatePickers.toggle()
                            if !showEventDatePickers {
                                addEventStart = Self.oneHourFromNow
                                addEventEnd   = Self.twoHoursFromNow
                            }
                        }
                    } label: {
                        Label(
                            showEventDatePickers ? "Remove dates" : "Set dates",
                            systemImage: showEventDatePickers ? "calendar.badge.minus" : "calendar.badge.plus"
                        )
                        .font(.caption)
                        .foregroundStyle(showEventDatePickers ? Color.secondary : Color.blue)
                    }
                    .buttonStyle(.plain).padding(.leading, 12)

                    if showEventDatePickers {
                        VStack(alignment: .leading, spacing: 4) {
                            DatePicker("Start", selection: $addEventStart,
                                       displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .onChange(of: addEventStart) { _, new in
                                    if addEventEnd <= new {
                                        addEventEnd = Calendar.current.date(
                                            byAdding: .hour, value: 1, to: new) ?? new
                                    }
                                }
                            DatePicker("End", selection: $addEventEnd, in: addEventStart...,
                                       displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                        }
                        .padding(.horizontal, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.bottom, 10)
            }
        }
        .background(Color(.windowBackgroundColor).opacity(0.5))
    }

    // MARK: - Reminder Actions

    private func loadAll() async {
        await loadReminders()
        await loadEvents()
    }

    private func loadReminders() async {
        reminderLoadState = .loading
        do {
            reminders = try await manager.fetchLinkedReminders(for: note)
            reminderLoadState = .loaded
        } catch let error as NSError where error.code == 401 {
            reminderLoadState = .denied
        } catch {
            reminderLoadState = .error(error.localizedDescription)
        }
    }

    private func toggleReminder(_ reminder: EKReminder) async {
        do {
            try await manager.updateReminder(
                identifier: reminder.calendarItemIdentifier,
                completed: !reminder.isCompleted)
            await loadReminders()
        } catch {
            reminderLoadState = .error(error.localizedDescription)
        }
    }

    private func deleteReminder(_ reminder: EKReminder) async {
        let id = reminder.calendarItemIdentifier
        do {
            try await manager.deleteReminder(identifier: id)
            if let link = note.linkedReminders.first(where: { $0.reminderIdentifier == id }) {
                modelContext.delete(link)
                try? modelContext.save()
            }
            reminders.removeAll { $0.calendarItemIdentifier == id }
        } catch {
            reminderLoadState = .error(error.localizedDescription)
        }
    }

    private func submitReminder() async {
        let title = addReminderTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        isSubmittingReminder = true
        do {
            try await manager.createReminder(
                title: title,
                dueDate: showReminderDueDatePicker ? addReminderDueDate : nil,
                in: note,
                context: modelContext)
            addReminderTitle          = ""
            showReminderDueDatePicker = false
            addReminderDueDate        = Self.oneHourFromNow
            reminderFieldFocused      = false
            await loadReminders()
        } catch {
            reminderLoadState = .error(error.localizedDescription)
        }
        isSubmittingReminder = false
    }

    // MARK: - Calendar Actions

    private func loadEvents() async {
        eventLoadState = .loading
        do {
            events = try await manager.fetchLinkedEvents(for: note)
            eventLoadState = .loaded
        } catch let error as NSError where error.code == 401 {
            eventLoadState = .denied
        } catch {
            eventLoadState = .error(error.localizedDescription)
        }
    }

    private func deleteCalendarEvent(_ event: EKEvent) async {
        let id = event.calendarItemIdentifier
        do {
            try await manager.deleteEvent(identifier: id)
            if let link = note.linkedCalendarEvents.first(where: { $0.eventIdentifier == id }) {
                modelContext.delete(link)
                try? modelContext.save()
            }
            events.removeAll { $0.calendarItemIdentifier == id }
        } catch {
            eventLoadState = .error(error.localizedDescription)
        }
    }

    private func submitEvent() async {
        let title = addEventTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let start = showEventDatePickers ? addEventStart : Self.oneHourFromNow
        let end   = showEventDatePickers ? addEventEnd   : Self.twoHoursFromNow
        isSubmittingEvent = true
        do {
            try await manager.createEvent(
                title: title,
                startDate: start,
                endDate: end,
                in: note,
                context: modelContext)
            addEventTitle        = ""
            showEventDatePickers = false
            addEventStart        = Self.oneHourFromNow
            addEventEnd          = Self.twoHoursFromNow
            eventFieldFocused    = false
            await loadEvents()
        } catch {
            eventLoadState = .error(error.localizedDescription)
        }
        isSubmittingEvent = false
    }

    // MARK: - Helpers

    private static var oneHourFromNow: Date {
        Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    }

    private static var twoHoursFromNow: Date {
        Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()
    }
}

// MARK: - ReminderRow

private struct ReminderRow: View {

    let reminder: EKReminder
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button(action: onToggle) {
                Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(reminder.isCompleted ? .green : .orange)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(reminder.isCompleted ? "Mark incomplete" : "Mark complete")
            .accessibilityHint(reminder.title ?? "")

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title ?? "Untitled")
                    .font(.callout)
                    .foregroundStyle(reminder.isCompleted ? .secondary : .primary)
                    .strikethrough(reminder.isCompleted, color: .secondary)
                    .lineLimit(2)

                if let chip = dueDateText {
                    Text(chip)
                        .font(.caption2)
                        .foregroundStyle(dueDateColor)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(dueDateColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Spacer(minLength: 0)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.quaternary)
                    .padding(4)
                    .background(Color(.separatorColor).opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Delete reminder")
            .accessibilityLabel("Delete \(reminder.title ?? "reminder")")
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var dueDateText: String? {
        guard !reminder.isCompleted,
              let components = reminder.dueDateComponents,
              let date = Calendar.current.date(from: components) else { return nil }
        let now = Date()
        let cal = Calendar.current
        if date < now {
            let days = cal.dateComponents([.day], from: date, to: now).day ?? 0
            return days == 0 ? "Overdue" : "Overdue · \(days)d"
        }
        if cal.isDateInToday(date)    { return "Today" }
        if cal.isDateInTomorrow(date) { return "Tomorrow" }
        let days = cal.dateComponents([.day], from: now, to: date).day ?? 0
        if days < 7 {
            let fmt = DateFormatter(); fmt.dateFormat = "EEEE"
            return fmt.string(from: date)
        }
        let fmt = DateFormatter(); fmt.dateStyle = .medium; fmt.timeStyle = .none
        return fmt.string(from: date)
    }

    private var dueDateColor: Color {
        guard !reminder.isCompleted,
              let components = reminder.dueDateComponents,
              let date = Calendar.current.date(from: components) else { return .secondary }
        if date < Date()                        { return .red    }
        if Calendar.current.isDateInToday(date) { return .orange }
        return .secondary
    }
}

// MARK: - EventRow

private struct EventRow: View {

    let event: EKEvent
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(calendarColor)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title ?? "Untitled")
                    .font(.callout)
                    .foregroundStyle(isPast ? .secondary : .primary)
                    .lineLimit(2)

                Text(dateRangeText)
                    .font(.caption2)
                    .foregroundStyle(dateColor)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(dateColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Spacer(minLength: 0)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.quaternary)
                    .padding(4)
                    .background(Color(.separatorColor).opacity(0.3))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Unlink event")
            .accessibilityLabel("Unlink \(event.title ?? "event")")
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var isPast: Bool { event.endDate < Date() }

    private var calendarColor: Color {
        guard let cal = event.calendar else { return .blue }
        return Color(cgColor: cal.cgColor)
    }

    private var dateRangeText: String {
        let fmt = DateIntervalFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: event.startDate, to: event.endDate)
    }

    private var dateColor: Color {
        if isPast { return .secondary }
        if Calendar.current.isDateInToday(event.startDate) { return .blue }
        return .secondary
    }
}

// MARK: - PanelLoadState

private enum PanelLoadState: Equatable {
    case idle
    case loading
    case loaded
    case denied
    case error(String)
}

// MARK: - Preview

#Preview {
    NoteRemindersPanel(note: Note(title: "Q2 Planning"))
        .modelContainer(for: [Note.self, LinkedReminder.self, LinkedCalendarEvent.self], inMemory: true)
}
