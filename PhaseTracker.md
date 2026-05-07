# 574 Phase Tracker

## Current Status

| Phase | Name | Status | Notes |
| --- | --- | --- | --- |
| 0 | Foundation | In progress | Core SwiftData models, three-column UI, Spotlight, MenuBarExtra, App Intents, and EventKit scaffolding exist. CloudKit configuration is now wired in code, but the app still needs validation on a signed iCloud-capable build. |
| 1 | Daily Driver (macOS) | In progress | Rich text editing, folders, tags, search, quick capture, Spotlight, and initial Reminders/Calendar linking exist. Attachments/search/integration depth still falls short of the defined milestone. |
| 2 | iOS & iPad | Not started | Shared views compile for iOS, but the planned iOS/iPad navigation scaffold and parity work are not built. |
| 3 | Calendar & Context | Not started | No embedded calendar, smart views, drag-to-reschedule, or conflict resolution layer yet. |
| 4 | Attachments & Export | Not started | Attachment model exists, but the full pipeline and export formats are not implemented. |
| 5 | Polish & Ship | Not started | Onboarding, performance hardening, accessibility audit, distribution prep, and pricing are still open. |

## Completed

- SwiftData models for notes, folders, tags, projects, attachments, reminders, and calendar links
- macOS three-column layout with folder, note list, and note detail panes
- Basic note CRUD, trash flow, folder/project organization, and theme settings
- Rich-text editor with formatting controls and inline image insertion
- Spotlight indexing and Spotlight handoff back into the app
- Menu bar quick capture on macOS
- App Intents for new note, add reminder, and open today's notes
- EventKit-based creation and loading for linked reminders and events

## Backlog

### Phase 0

- Validate CloudKit syncing end-to-end in a signed environment and resolve any container issues
- Replace silent `try?` persistence paths with explicit error handling in user-facing flows
- Add real tests around model seeding, trash expiry, and persistence behavior

### Phase 1

- Reuse existing tags instead of creating duplicates for the same name
- Add attachment browsing and inline rendering beyond editor-only pasted images
- Deepen Calendar integration from create/read/delete to full edit/reschedule behavior
- Expand search beyond in-memory title/body filtering

### Phase 2

- Build the planned iPhone/iPad `TabView` shell
- Separate navigation patterns for compact vs regular width

### Phase 3

- Ship Home/Today smart views that combine notes, reminders, and events
- Add calendar surfaces and conflict-resolution rules

### Phase 4

- Implement export formats: PDF, Markdown, JSON, CSV/HTML/DOCX as finalized
- Build a real attachment pipeline with file bookmarks and previews

### Phase 5

- Add first-launch onboarding and sync/privacy settings
- Profile large libraries and address editor/list performance
- Finalize iconography, branding, screenshots, and release readiness
