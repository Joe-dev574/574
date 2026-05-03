//  RichTextEditorView.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  Phase D — Inline Images (fixed resize menu crash).
//  • Photo button opens image picker
//  • Drag-and-drop works
//  • Paste works
//  • Images auto-resize on insert
//  • Right-click on image → resize menu (only shows when on an image)
//
import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
typealias PlatformImage = NSImage
#else
import UIKit
import PhotosUI
typealias PlatformImage = UIImage
#endif
struct RichTextEditorView: View {
@Binding var attributedText: NSAttributedString
@State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
#if os(iOS)
@State private var showingImagePicker = false
@State private var selectedPhotoItem: PhotosPickerItem?
#endif
var body: some View {
VStack(spacing: 0) {
toolbar
Divider()
nativeTextView
}
.accessibilityElement(children: .contain)
.accessibilityLabel("Rich text editor")
#if os(iOS)
.photosPicker(isPresented: $showingImagePicker, selection: $selectedPhotoItem, matching: .images)
.onChange(of: selectedPhotoItem) { _, item in
    Task { @MainActor in
        guard let data = try? await item?.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        insertImage(image)
        selectedPhotoItem = nil
    }
}
#endif
}
private var toolbar: some View {
ScrollView(.horizontal, showsIndicators: false) {
HStack(spacing: 4) {
Menu {
Button("Heading 1") { applyHeading(level: 1) }
Button("Heading 2") { applyHeading(level: 2) }
Button("Heading 3") { applyHeading(level: 3) }
} label: { Image(systemName: "textformat.size") }
.buttonStyle(.borderless)
Divider().frame(height: 18)
toolbarButton(icon: "bold", help: "Bold", action: applyBold)
toolbarButton(icon: "italic", help: "Italic", action: applyItalic)
toolbarButton(icon: "underline", help: "Underline", action: applyUnderline)
toolbarButton(icon: "strikethrough", help: "Strikethrough", action: applyStrikethrough)
Divider().frame(height: 18)
toolbarButton(icon: "list.bullet", help: "Bullet List", action: applyBulletList)
toolbarButton(icon: "list.number", help: "Numbered List", action: applyNumberedList)
toolbarButton(icon: "checklist", help: "Checklist", action: applyChecklist)
Divider().frame(height: 18)
toolbarButton(icon: "curlybraces", help: "Code block", action: applyCodeBlock)
toolbarButton(icon: "link", help: "Insert link", action: insertLink)
Divider().frame(height: 18)
toolbarButton(icon: "photo", help: "Insert Image", action: showImagePicker)
Spacer()
}
.padding(.horizontal, 12)
.padding(.vertical, 6)
}
.background(Color.black.opacity(0.06))
}
private func toolbarButton(icon: String, help: String, action: @escaping () -> Void) -> some View {
Button(action: action) {
Image(systemName: icon)
.frame(width: 28, height: 28)
}
.buttonStyle(.borderless)
.help(help)
.accessibilityLabel(help)
}
// MARK: - Formatting Actions (unchanged from Phase C)
private func applyHeading(level: Int) { mutate { TextFormatting.applyHeading(level: level, to: $0, range: selectedRange) } }
private func applyBold()          { mutate { TextFormatting.applyBold(to: $0, range: selectedRange) } }
private func applyItalic()        { mutate { TextFormatting.applyItalic(to: $0, range: selectedRange) } }
private func applyUnderline()     { mutate { TextFormatting.applyUnderline(to: $0, range: selectedRange) } }
private func applyStrikethrough() { mutate { TextFormatting.applyStrikethrough(to: $0, range: selectedRange) } }
private func applyChecklist()     { mutate { TextFormatting.applyChecklist(to: $0, range: selectedRange) } }
private func applyCodeBlock()     { mutate { TextFormatting.applyCodeBlock(to: $0, range: selectedRange) } }
private func applyBulletList()    { mutate { TextFormatting.applyBulletList(to: $0, range: selectedRange) } }
private func applyNumberedList()  { mutate { TextFormatting.applyNumberedList(to: $0, range: selectedRange) } }
private func insertLink()         { mutate { TextFormatting.insertLink(urlString: "https://", to: $0, range: selectedRange) } }
// MARK: - Phase D: Image Handling
private func showImagePicker() {
#if os(macOS)
let panel = NSOpenPanel()
panel.allowedContentTypes = [.png, .jpeg, .tiff, .gif]
panel.allowsMultipleSelection = false
panel.canChooseDirectories = false
panel.begin { response in
guard response == .OK, let url = panel.url, let image = NSImage(contentsOf: url) else { return }
self.insertImage(image)
}
#else
showingImagePicker = true
#endif
}
private func insertImage(_ image: PlatformImage) {
mutate { mutable in
let resized = image.resizedToFit(maxWidth: 700)
let attachment = NSTextAttachment()
attachment.image = resized
let attachmentString = NSAttributedString(attachment: attachment)
mutable.insert(attachmentString, at: selectedRange.location)
}
}
private func mutate(_ transform: (NSMutableAttributedString) -> Void) {
let mutable = NSMutableAttributedString(attributedString: attributedText)
transform(mutable)
attributedText = mutable
}
@ViewBuilder
private var nativeTextView: some View {
#if os(macOS)
RichTextEditorRepresentableMac(attributedText: $attributedText, selectedRange: $selectedRange)
#else
RichTextEditorRepresentableiOS(attributedText: $attributedText, selectedRange: $selectedRange)
#endif
}
}
// MARK: - macOS Interactive Editor
#if os(macOS)
struct RichTextEditorRepresentableMac: NSViewRepresentable {
@Binding var attributedText: NSAttributedString
@Binding var selectedRange: NSRange
func makeNSView(context: Context) -> NSScrollView {
let textView = InteractiveTextView()
textView.isRichText = true
textView.allowsUndo = true
textView.font = NSFont.systemFont(ofSize: 16)
textView.textContainerInset = NSSize(width: 24, height: 24)
textView.drawsBackground = false
textView.delegate = context.coordinator
textView.registerForDraggedTypes([.png, .tiff, .fileURL])
textView.textStorage?.setAttributedString(attributedText)
let scrollView = NSScrollView()
scrollView.documentView = textView
scrollView.hasVerticalScroller = true
scrollView.autohidesScrollers = true
return scrollView
}
func updateNSView(_ scrollView: NSScrollView, context: Context) {
guard let textView = scrollView.documentView as? NSTextView else { return }
guard textView.attributedString() != attributedText else { return }
context.coordinator.isUpdatingFromSwiftUI = true
textView.textStorage?.setAttributedString(attributedText)
context.coordinator.isUpdatingFromSwiftUI = false
}
func makeCoordinator() -> Coordinator { Coordinator(self) }
final class Coordinator: NSObject, NSTextViewDelegate {
var parent: RichTextEditorRepresentableMac
var isUpdatingFromSwiftUI = false
init(_ parent: RichTextEditorRepresentableMac) { self.parent = parent }
func textDidChange(_ notification: Notification) {
guard !isUpdatingFromSwiftUI, let textView = notification.object as? NSTextView else { return }
DispatchQueue.main.async { self.parent.attributedText = textView.attributedString() }
}
func textViewDidChangeSelection(_ notification: Notification) {
guard !isUpdatingFromSwiftUI, let textView = notification.object as? NSTextView else { return }
DispatchQueue.main.async { self.parent.selectedRange = textView.selectedRange() }
}
}
}
final class InteractiveTextView: NSTextView {
// Checklist toggle (Phase C)
override func mouseDown(with event: NSEvent) {
let point = convert(event.locationInWindow, from: nil)
let index = characterIndex(for: point)
guard index != NSNotFound else {
super.mouseDown(with: event)
return
}
let attrString = attributedString()
let paragraphRange = (attrString.string as NSString).paragraphRange(for: NSRange(location: index, length: 1))
if paragraphRange.length > 2 {
let prefixRange = NSRange(location: paragraphRange.location, length: 2)
let prefix = attrString.attributedSubstring(from: prefixRange).string
if prefix == "☐ " || prefix == "✓ " {
TextFormatting.toggleChecklist(at: paragraphRange.location, in: textStorage!)
return
}
}
super.mouseDown(with: event)
}
// Drag & Paste
override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
let pasteboard = sender.draggingPasteboard
if let image = NSImage(pasteboard: pasteboard) {
insertImage(image)
return true
}
if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
let url = urls.first,
let image = NSImage(contentsOf: url) {
insertImage(image)
return true
}
return super.performDragOperation(sender)
}
override func paste(_ sender: Any?) {
let pasteboard = NSPasteboard.general
if let image = NSImage(pasteboard: pasteboard) {
insertImage(image)
return
}
super.paste(sender)
}
private func insertImage(_ image: NSImage) {
let resized = image.resizedToFit(maxWidth: 700)
let attachment = NSTextAttachment()
attachment.image = resized
let attachmentString = NSAttributedString(attachment: attachment)
textStorage?.insert(attachmentString, at: selectedRange().location)
}
// Resize context menu (only show when clicking on an image)
override func menu(for event: NSEvent) -> NSMenu? {
let superMenu = super.menu(for: event) ?? NSMenu()
let point = convert(event.locationInWindow, from: nil)
let index = characterIndex(for: point)
guard index != NSNotFound else { return superMenu }
let attrString = attributedString()
guard let attachment = attrString.attribute(.attachment, at: index, effectiveRange: nil) as? NSTextAttachment,
attachment.image != nil else {
return superMenu
}
let resizeItem = NSMenuItem(title: "Resize Image", action: nil, keyEquivalent: "")
let submenu = NSMenu()
submenu.addItem(withTitle: "Small", action: #selector(resizeSelectedImage(_:)), keyEquivalent: "")
submenu.addItem(withTitle: "Medium", action: #selector(resizeSelectedImage(_:)), keyEquivalent: "")
submenu.addItem(withTitle: "Large", action: #selector(resizeSelectedImage(_:)), keyEquivalent: "")
submenu.addItem(withTitle: "Original", action: #selector(resizeSelectedImage(_:)), keyEquivalent: "")
resizeItem.submenu = submenu
superMenu.addItem(resizeItem)
return superMenu
}
@objc private func resizeSelectedImage(_ sender: NSMenuItem) {
guard let textStorage = textStorage else { return }
let range = selectedRange()
guard range.location != NSNotFound,
let attachment = textStorage.attribute(.attachment, at: range.location, effectiveRange: nil) as? NSTextAttachment,
let image = attachment.image else { return }
let scale: CGFloat = {
switch sender.title {
case "Small": return 0.5
case "Medium": return 0.75
case "Large": return 1.0
default: return 1.0
}
}()
let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
attachment.image = image.resizedToFit(maxWidth: newSize.width)
textStorage.addAttribute(.attachment, value: attachment, range: range)
}
}
// Resize helper
extension NSImage {
func resizedToFit(maxWidth: CGFloat) -> NSImage {
let scale = maxWidth / size.width
let newSize = CGSize(width: maxWidth, height: size.height * scale)
let newImage = NSImage(size: newSize)
newImage.lockFocus()
draw(in: NSRect(origin: .zero, size: newSize))
newImage.unlockFocus()
return newImage
}
}
#endif
// MARK: - iOS: UITextView Representable
#if os(iOS)
struct RichTextEditorRepresentableiOS: UIViewRepresentable {

    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable             = true
        textView.isSelectable           = true
        textView.font                   = UIFont.systemFont(ofSize: 16)
        textView.textContainerInset     = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.backgroundColor        = .clear
        textView.allowsEditingTextAttributes = true
        textView.delegate               = context.coordinator
        textView.attributedText         = attributedText
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        guard !context.coordinator.isUpdatingFromUser else { return }
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditorRepresentableiOS
        var isUpdatingFromUser = false

        init(_ parent: RichTextEditorRepresentableiOS) { self.parent = parent }

        func textViewDidChange(_ textView: UITextView) {
            isUpdatingFromUser = true
            parent.attributedText = textView.attributedText
            isUpdatingFromUser = false
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
    }
}

extension UIImage {
    func resizedToFit(maxWidth: CGFloat) -> UIImage {
        guard size.width > maxWidth else { return self }
        let scale = maxWidth / size.width
        let newSize = CGSize(width: maxWidth, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
#endif
