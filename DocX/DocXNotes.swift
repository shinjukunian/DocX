//
//  DocXNotes.swift
//  DocX
//

import Foundation
import AEXML

/// Identifies whether we are exporting footnotes or endnotes and provides the
/// OOXML names and attributed-string keys associated with that note kind.
enum DocXNoteKind {
    case footnote
    case endnote

    var referenceAttribute: NSAttributedString.Key {
        switch self {
        case .footnote: return .footnoteReferenceId
        case .endnote: return .endnoteReferenceId
        }
    }

    var bodyAttribute: NSAttributedString.Key {
        switch self {
        case .footnote: return .footnoteBodyId
        case .endnote: return .endnoteBodyId
        }
    }

    var rootElementName: String {
        switch self {
        case .footnote: return "w:footnotes"
        case .endnote: return "w:endnotes"
        }
    }

    var noteElementName: String {
        switch self {
        case .footnote: return "w:footnote"
        case .endnote: return "w:endnote"
        }
    }

    var relationshipTarget: String {
        switch self {
        case .footnote: return "footnotes"
        case .endnote: return "endnotes"
        }
    }

    var contentType: String {
        switch self {
        case .footnote:
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml"
        case .endnote:
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml"
        }
    }

    var paragraphNoteReferenceKind: ParagraphElement.NoteReferenceKind {
        switch self {
        case .footnote: return .footnote
        case .endnote: return .endnote
        }
    }

}

/// The collected content for a single note body keyed by its note id.
struct DocXNoteDefinition {
    let id: Int
    let attributedString: NSAttributedString
}

/// Collects note bodies from an attributed string and emits `footnotes.xml` or
/// `endnotes.xml` content for the docx package.
///
/// The source attributed string uses custom attributes to identify:
/// - note references in the main document (`footnoteReferenceId` / `endnoteReferenceId`)
/// - note body paragraphs (`footnoteBodyId` / `endnoteBodyId`)
///
/// This type groups body paragraphs by note id, preserves their paragraph
/// boundaries, and then renders the corresponding XML parts.
struct DocXNoteConfiguration {
    private let footnotes: [DocXNoteDefinition]
    private let endnotes: [DocXNoteDefinition]

    init(attributedString: NSAttributedString) {
        self.footnotes = Self.noteDefinitions(in: attributedString, kind: .footnote)
        self.endnotes = Self.noteDefinitions(in: attributedString, kind: .endnote)
    }

    var hasFootnotes: Bool { !footnotes.isEmpty }
    var hasEndnotes: Bool { !endnotes.isEmpty }

    /// Returns one attributed string containing all note bodies of `kind`.
    ///
    /// This is used when preparing relationships for note content, such as
    /// links and images embedded inside notes.
    func combinedAttributedString(for kind: DocXNoteKind) -> NSAttributedString? {
        let notes = notes(for: kind)
        guard !notes.isEmpty else { return nil }

        let combined = NSMutableAttributedString()
        for note in notes {
            combined.append(note.attributedString)
        }
        return combined
    }

    /// Builds the XML document for either `footnotes.xml` or `endnotes.xml`.
    func notesXML(for kind: DocXNoteKind,
                  linkRelations: [DocumentRelationship],
                  options: DocXOptions) -> String {
        var xmlOptions = AEXMLOptions()
        xmlOptions.documentHeader.standalone = "yes"
        xmlOptions.escape = true
        xmlOptions.lineSeparator = "\n"

        let root = AEXMLElement(name: kind.rootElementName,
                                value: nil,
                                attributes: [
                                    "xmlns:w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
                                    "xmlns:r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
                                ])
        let document = AEXMLDocument(root: root, options: xmlOptions)
        root.addChildren(separatorElements(for: kind))

        for note in notes(for: kind) {
            let noteElement = AEXMLElement(name: kind.noteElementName,
                                           value: nil,
                                           attributes: ["w:id": "\(note.id)"])
            let paragraphRanges = note.attributedString.paragraphRanges
            let paragraphs = note.attributedString.buildParagraphs(paragraphRanges: paragraphRanges,
                                                                   linkRelations: linkRelations,
                                                                   options: options,
                                                                   leadingNoteBodyReferenceKind: kind.paragraphNoteReferenceKind)
            noteElement.addChildren(paragraphs)
            root.addChild(noteElement)
        }

        return document.xmlCompact
    }

    private func notes(for kind: DocXNoteKind) -> [DocXNoteDefinition] {
        switch kind {
        case .footnote: return footnotes
        case .endnote: return endnotes
        }
    }

    /// Extracts note body paragraphs from `attributedString`, grouping them by
    /// note id while preserving their paragraph breaks.
    private static func noteDefinitions(in attributedString: NSAttributedString,
                                        kind: DocXNoteKind) -> [DocXNoteDefinition] {
        var noteStrings = [Int: NSMutableAttributedString]()
        var orderedIds = [Int]()

        for paragraphRange in attributedString.paragraphRanges {
            let noteId: Int?
            switch kind {
            case .footnote:
                noteId = paragraphRange.footnoteBodyId
            case .endnote:
                noteId = paragraphRange.endnoteBodyId
            }

            guard let noteId else { continue }
            if noteStrings[noteId] == nil {
                noteStrings[noteId] = NSMutableAttributedString()
                orderedIds.append(noteId)
            }

            let paragraph = NSMutableAttributedString(attributedString: attributedString.attributedSubstring(from: paragraphRange.range))
            let breakString = NSAttributedString(string: "\r", attributes: [.breakType: paragraphRange.breakType])
            paragraph.append(breakString)
            noteStrings[noteId]?.append(paragraph)
        }

        return orderedIds.compactMap { noteId in
            guard let noteString = noteStrings[noteId] else { return nil }
            return DocXNoteDefinition(id: noteId, attributedString: noteString)
        }
    }

    /// Returns the two built-in note separator definitions Word expects.
    ///
    /// `separator` (id `-1`) is the normal rule/marker shown before the note area
    /// on a page. `continuationSeparator` (id `0`) is the alternate marker Word
    /// uses when a note continues from a previous page into the current one.
    private func separatorElements(for kind: DocXNoteKind) -> [AEXMLElement] {
        [separatorElement(for: kind, id: -1, type: "separator", childName: "w:separator"),
         separatorElement(for: kind, id: 0, type: "continuationSeparator", childName: "w:continuationSeparator")]
    }

    private func separatorElement(for kind: DocXNoteKind,
                                  id: Int,
                                  type: String,
                                  childName: String) -> AEXMLElement {
        let noteElement = AEXMLElement(name: kind.noteElementName,
                                       value: nil,
                                       attributes: ["w:type": type, "w:id": "\(id)"])
        let paragraph = AEXMLElement(name: "w:p")
        let run = AEXMLElement(name: "w:r")
        run.addChild(AEXMLElement(name: childName))
        paragraph.addChild(run)
        noteElement.addChild(paragraph)
        return noteElement
    }
}
