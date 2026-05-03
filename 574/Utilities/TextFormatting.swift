//
//  TextFormatting.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  Phase C complete — Bullet/Numbered lists + interactive checklists.
//


import Foundation
import SwiftUI



#if os(macOS)
import AppKit
#else
import UIKit
#endif
struct TextFormatting {
    // MARK: - Headings
    static func applyHeading(level: Int, to attributedString: NSMutableAttributedString, range: NSRange? = nil) {
        let effectiveRange = range ?? NSRange(location: 0, length: attributedString.length)
        let fontSize: CGFloat = level == 1 ? 24 : (level == 2 ? 20 : 18)
#if os(macOS)
        let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
#else
        let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
#endif
        attributedString.addAttribute(.font, value: font, range: effectiveRange)
    }
    // MARK: - Inline Formatting
    static func applyBold(to attributedString: NSMutableAttributedString, range: NSRange? = nil) {
        let effectiveRange = range ?? NSRange(location: 0, length: attributedString.length)
#if os(macOS)
        toggleFontTrait(.boldFontMask, on: attributedString, range: effectiveRange)
#else
        toggleFontTrait(.traitBold, on: attributedString, range: effectiveRange)
#endif
    }
    static func applyItalic(to attributedString: NSMutableAttributedString, range: NSRange? = nil) {
        let effectiveRange = range ?? NSRange(location: 0, length: attributedString.length)
#if os(macOS)
        toggleFontTrait(.italicFontMask, on: attributedString, range: effectiveRange)
#else
        toggleFontTrait(.traitItalic, on: attributedString, range: effectiveRange)
#endif
    }
    static func applyUnderline(to attributedString: NSMutableAttributedString, range: NSRange? = nil) {
        let effectiveRange = range ?? NSRange(location: 0, length: attributedString.length)
        let current = attributedString.attribute(.underlineStyle, at: max(effectiveRange.location, 0), effectiveRange: nil) as? Int ?? 0
        let newStyle = current == NSUnderlineStyle.single.rawValue ? 0 : NSUnderlineStyle.single.rawValue
        attributedString.addAttribute(.underlineStyle, value: newStyle, range: effectiveRange)
    }
    static func applyStrikethrough(to attributedString: NSMutableAttributedString, range: NSRange? = nil) {
        let effectiveRange = range ?? NSRange(location: 0, length: attributedString.length)
        let current = attributedString.attribute(.strikethroughStyle, at: max(effectiveRange.location, 0), effectiveRange: nil) as? Int ?? 0
        let newStyle = current == NSUnderlineStyle.single.rawValue ? 0 : NSUnderlineStyle.single.rawValue
        attributedString.addAttribute(.strikethroughStyle, value: newStyle, range: effectiveRange)
    }
    // MARK: - Phase C: Lists
    static func applyBulletList(to attributedString: NSMutableAttributedString, range: NSRange? = nil) {
        let effectiveRange = range ?? NSRange(location: 0, length: attributedString.length)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.textLists = [NSTextList(markerFormat: .disc, options: 0)]
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: effectiveRange)
    }
    static func applyNumberedList(to attributedString: NSMutableAttributedString, range: NSRange? = nil) {
        let effectiveRange = range ?? NSRange(location: 0, length: attributedString.length)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.textLists = [NSTextList(markerFormat: .decimal, options: 0)]
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: effectiveRange)
    }
    static func toggleChecklist(at index: Int, in attributedString: NSMutableAttributedString) {
        guard index >= 0 && index < attributedString.length else { return }
        let paragraphRange = (attributedString.string as NSString).paragraphRange(for: NSRange(location: index, length: 1))
        if paragraphRange.length > 2 {
            let prefixRange = NSRange(location: paragraphRange.location, length: 2)
            let prefix = attributedString.attributedSubstring(from: prefixRange).string
            if prefix == "☐ " {
                attributedString.replaceCharacters(in: prefixRange, with: "✓ ")
            } else if prefix == "✓ " {
                attributedString.replaceCharacters(in: prefixRange, with: "☐ ")
            }
        }
    }
    static func applyChecklist(to attributedString: NSMutableAttributedString, range: NSRange? = nil) {
        let effectiveRange = range ?? NSRange(location: 0, length: attributedString.length)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 28
        paragraphStyle.firstLineHeadIndent = 0
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 28)]
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: effectiveRange)
        let checkbox = NSAttributedString(string: "☐ ", attributes: [.paragraphStyle: paragraphStyle])
        attributedString.insert(checkbox, at: effectiveRange.location)
    }
    static func applyCodeBlock(to attributedString: NSMutableAttributedString, range: NSRange? = nil) {
        let effectiveRange = range ?? NSRange(location: 0, length: attributedString.length)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 12
        paragraphStyle.firstLineHeadIndent = 12
#if os(macOS)
        let monoFont   = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let background = NSColor.systemGray.withAlphaComponent(0.2)
#else
        let monoFont   = UIFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let background = UIColor.systemGray.withAlphaComponent(0.2)
#endif
        attributedString.addAttribute(.font, value: monoFont, range: effectiveRange)
        attributedString.addAttribute(.backgroundColor, value: background, range: effectiveRange)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: effectiveRange)
    }
    static func insertLink(urlString: String, to attributedString: NSMutableAttributedString, range: NSRange? = nil) {
        let effectiveRange = range ?? NSRange(location: 0, length: attributedString.length)
        guard let url = URL(string: urlString) else { return }
        attributedString.addAttribute(.link, value: url, range: effectiveRange)
    }
    // MARK: - Private Helpers
#if os(macOS)
    private static func toggleFontTrait(_ trait: NSFontTraitMask, on attributedString: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0 else { return }
        attributedString.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            guard let font = value as? NSFont else { return }
            let newFont = NSFontManager.shared.convert(font, toHaveTrait: trait)
            attributedString.addAttribute(.font, value: newFont, range: subrange)
        }
    }
#else
    private static func toggleFontTrait(_ trait: UIFontDescriptor.SymbolicTraits, on attributedString: NSMutableAttributedString, range: NSRange) {
        guard range.length > 0 else { return }
        attributedString.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
            guard let font = value as? UIFont else { return }
            let descriptor = font.fontDescriptor
            var traits = descriptor.symbolicTraits
            if traits.contains(trait) { traits.remove(trait) } else { traits.insert(trait) }
            guard let newDescriptor = descriptor.withSymbolicTraits(traits) else { return }
            let newFont = UIFont(descriptor: newDescriptor, size: font.pointSize)
            attributedString.addAttribute(.font, value: newFont, range: subrange)
        }
    }
#endif
}
