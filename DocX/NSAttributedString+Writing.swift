//
//  NSAttributedString+DocX.swift
//
//
//  Created by Morten Bertz on 2021/03/23.
//

import Foundation
import ZIPFoundation
import AEXML

extension NSAttributedString {
    func writeDocX_builtin(to url: URL, options: DocXOptions = DocXOptions()) throws {
        try [self].writeDocXSections(to: url, options: options)
    }
}

extension Array where Element == NSAttributedString {
    func writeDocXSections(to url: URL, options: DocXOptions = DocXOptions()) throws {
        let tempURL = try FileManager.default.url(for: .itemReplacementDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: url,
                                                  create: true)

        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }

        let docURL = tempURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        guard let blankURL = Bundle.blankDocumentURL else { throw DocXSavingErrors.noBlankDocument }
        try FileManager.default.copyItem(at: blankURL, to: docURL)

        let wordSubdirURL = docURL.appendingPathComponent("word")
        let docPath = wordSubdirURL.appendingPathComponent("document").appendingPathExtension("xml")
        let linkURL = wordSubdirURL.appendingPathComponent("_rels").appendingPathComponent("document.xml.rels")
        let mediaURL = wordSubdirURL.appendingPathComponent("media", isDirectory: true)
        let propsURL = docURL.appendingPathComponent("docProps").appendingPathComponent("core").appendingPathExtension("xml")
        let settingsURL = wordSubdirURL.appendingPathComponent("settings").appendingPathExtension("xml")

        // If the DocXOptions contains a styles configuration with a valid styles XML document,
        // then write that into the docx
        let configStylesXMLDocument = options.styleConfiguration?.stylesXMLDocument
        if let configStylesXMLDocument {
            // Construct the path for the `styles.xml` file
            let stylesURL = wordSubdirURL.appendingPathComponent("styles").appendingPathExtension("xml")
            try configStylesXMLDocument.xmlCompact.write(to: stylesURL, atomically: true, encoding: .utf8)
        }

        // Combine all sections, appending a section-preserving paragraph boundary
        // when required
        //
        // A section-preserving paragraph boundary is required, for instance,
        // if section 1 ends with an endnote body paragraph and section 2
        // starts with the heading "Chapter 2". Concatenating them directly would
        // make the heading look like more text in that final endnote paragraph.
        // Inserting the separator keeps the note body and the next section's
        // opening paragraph distinct during later paragraph-range processing.
        let combinedAttributedString = NSMutableAttributedString(string: "")
        for section in self {
            combinedAttributedString.appendSectionPreservingParagraphBoundary(section)
        }

        // Make sure we don't have duplicate footnote or endnote IDs
        try validateNoteIds(in: combinedAttributedString)

        let allParagraphRanges = combinedAttributedString.paragraphRanges
        
        // Collect list numbering info
        var numberingConfig = DocXNumberingConfiguration()
        for range in allParagraphRanges {
            if let numId = range.numberingId, let style = range.listStyle {
                numberingConfig.register(numId: numId,
                                         style: style,
                                         level: range.numberingLevel ?? 0)
            }
        }
        
        // If any paragraphs have `.listNumberingId` and `.listStyle` attributes,
        // generate the numbering.xml
        if numberingConfig.hasNumbering {
            let numberingURL = wordSubdirURL.appendingPathComponent("numbering").appendingPathExtension("xml")
            try numberingConfig.numberingXML().write(to: numberingURL, atomically: true, encoding: .utf8)
        }

        // Collect endnotes and footnotes attributes
        // If we find any, we'll generate the endnotes.xml and/or footnotes.xml
        let noteConfig = DocXNoteConfiguration(attributedString: combinedAttributedString)
        
        // Generate the footnotes.xml, if we found any footnotes
        if noteConfig.hasFootnotes {
            let footnotesURL = wordSubdirURL.appendingPathComponent("footnotes").appendingPathExtension("xml")
            let footnotesRelsURL = wordSubdirURL.appendingPathComponent("_rels").appendingPathComponent("footnotes.xml.rels")
            let footnoteRelsDocument = emptyRelationshipsDocument()
            let footnoteRelations = noteConfig.combinedAttributedString(for: .footnote)?
                .prepareLinks(linkXML: footnoteRelsDocument,
                              mediaURL: mediaURL,
                              options: options,
                              mediaFilenamePrefix: "footnotes-") ?? []
            try noteConfig.notesXML(for: .footnote,
                                    linkRelations: footnoteRelations,
                                    options: options).write(to: footnotesURL,
                                                            atomically: true,
                                                            encoding: .utf8)
            if !footnoteRelsDocument.root.children.isEmpty {
                try footnoteRelsDocument.xmlCompact.write(to: footnotesRelsURL, atomically: true, encoding: .utf8)
            }
        }

        // Generate the endnotes.xml, if we found any endnotes
        if noteConfig.hasEndnotes {
            let endnotesURL = wordSubdirURL.appendingPathComponent("endnotes").appendingPathExtension("xml")
            let endnotesRelsURL = wordSubdirURL.appendingPathComponent("_rels").appendingPathComponent("endnotes.xml.rels")
            let endnoteRelsDocument = emptyRelationshipsDocument()
            let endnoteRelations = noteConfig.combinedAttributedString(for: .endnote)?
                .prepareLinks(linkXML: endnoteRelsDocument,
                              mediaURL: mediaURL,
                              options: options,
                              mediaFilenamePrefix: "endnotes-") ?? []
            try noteConfig.notesXML(for: .endnote,
                                    linkRelations: endnoteRelations,
                                    options: options).write(to: endnotesURL,
                                                            atomically: true,
                                                            encoding: .utf8)
            if !endnoteRelsDocument.root.children.isEmpty {
                try endnoteRelsDocument.xmlCompact.write(to: endnotesRelsURL, atomically: true, encoding: .utf8)
            }
        }

        let linkData = try Data(contentsOf: linkURL)
        var docOptions = AEXMLOptions()
        docOptions.parserSettings.shouldTrimWhitespace = false
        docOptions.documentHeader.standalone = "yes"
        
        // Enable escaping so that reserved characters, like < & >, don't
        // result in an invalid docx file
        // See: https://github.com/shinjukunian/DocX/issues/24
        docOptions.escape = true

        let linkDocument = try AEXMLDocument(xml: linkData, options: docOptions)

        if let endnotePosition = options.endnotePosition {
            try updateSettingsXML(at: settingsURL, endnotePosition: endnotePosition)
        }

        // If we have a styles.xml file, `document.xml.rels` needs to include a link to it
        if configStylesXMLDocument != nil {
            addRelationship(to: linkDocument,
                            for: combinedAttributedString,
                            type: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles",
                            target: "styles.xml")
        }

        // If we have a numbering.xml file, `document.xml.rels` needs to include a link to it
        if numberingConfig.hasNumbering {
            addRelationship(to: linkDocument,
                            for: combinedAttributedString,
                            type: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering",
                            target: "numbering.xml")
        }

        // If we have a footnotes.xml file, `document.xml.rels` needs to include a link to it
        if noteConfig.hasFootnotes {
            addRelationship(to: linkDocument,
                            for: combinedAttributedString,
                            type: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/footnotes",
                            target: "footnotes.xml")
        }

        // If we have a endnotes.xml file, `document.xml.rels` needs to include a link to it
        if noteConfig.hasEndnotes {
            addRelationship(to: linkDocument,
                            for: combinedAttributedString,
                            type: "http://schemas.openxmlformats.org/officeDocument/2006/relationships/endnotes",
                            target: "endnotes.xml")
        }

        // Update the [Content_Types].xml if necessary
        if numberingConfig.hasNumbering || noteConfig.hasFootnotes || noteConfig.hasEndnotes {
            try updateContentTypesXML(at: docURL,
                                      hasNumbering: numberingConfig.hasNumbering,
                                      hasFootnotes: noteConfig.hasFootnotes,
                                      hasEndnotes: noteConfig.hasEndnotes)
        }

        let linkRelations = combinedAttributedString.prepareLinks(linkXML: linkDocument, mediaURL: mediaURL, options: options)
        try linkDocument.xmlCompact.write(to: linkURL, atomically: true, encoding: .utf8)

        let xmlData = try combinedAttributedString.docXDocument(sectionStrings: self,
                                                                linkRelations: linkRelations,
                                                                options: options)
        try xmlData.write(to: docPath, atomically: true, encoding: .utf8)

        try options.xml.xmlCompact.write(to: propsURL, atomically: true, encoding: .utf8)

        let zipURL = tempURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("zip")
        try FileManager.default.zipItem(at: docURL,
                                        to: zipURL,
                                        shouldKeepParent: false,
                                        compressionMethod: .deflate,
                                        progress: nil)

        // Attempt to copy the docx file to its final destination
        // We expect this will fail if a file already exists there
        do {
            try FileManager.default.copyItem(at: zipURL, to: url)
        } catch {
            // If the copy failed, attempt to replace the file
            let _ = try FileManager.default.replaceItemAt(url,
                                                          withItemAt: zipURL,
                                                          backupItemName: nil,
                                                          options: .usingNewMetadataOnly)
        }
    }
}

private extension NSMutableAttributedString {
    func appendSectionPreservingParagraphBoundary(_ section: NSAttributedString) {
        guard length > 0 else {
            append(section)
            return
        }

        if !endsWithParagraphSeparator {
            append(NSAttributedString(string: "\r"))
        }

        append(section)
    }

    var endsWithParagraphSeparator: Bool {
        guard let lastScalar = string.unicodeScalars.last else {
            return false
        }
        return CharacterSet.newlines.contains(lastScalar)
    }
}

/// Throws if any footnote or endnote reference ID appears more than once in the
/// combined attributed string. Each note ID must be globally unique.
private func validateNoteIds(in attributedString: NSAttributedString) throws {
    let fullRange = NSRange(location: 0, length: attributedString.length)
    
    for (key, kind) in [
        (NSAttributedString.Key.footnoteReferenceId, "footnote"),
        (NSAttributedString.Key.endnoteReferenceId, "endnote")
    ] {
        var foundNoteIDs = Set<Int>()
        var duplicateID: Int?
        attributedString.enumerateAttribute(key, in: fullRange, options: []) { value, _, stop in
            if let id = value as? Int {
                if foundNoteIDs.contains(id) {
                    duplicateID = id
                    stop.pointee = true
                }
                foundNoteIDs.insert(id)
            }
        }
        if let id = duplicateID {
            throw DocXSavingErrors.duplicateNoteId(kind: kind, id: id)
        }
    }
}

private func addRelationship(to linkDocument: AEXMLDocument,
                             for attributedString: NSAttributedString,
                             type: String,
                             target: String) {
    // Construct the attributes for the Relationship to the target filename.
    // This Relationship needs a unique id (one greater than the last "rId{#}")
    // and always points to the supplied target.
    let newRelationshipIndex = attributedString.lastRelationshipIdIndex(linkXML: linkDocument) + 1
    let newIdString = "rId\(newRelationshipIndex)"
    let attributes = ["Id": newIdString,
                      "Type": type,
                      "Target": target]

    // Add the Relationship.
    linkDocument.root.addChild(name: "Relationship", value: nil, attributes: attributes)
}

/// Updates the "[Content_Types].xml" file that is part of our "blank" Word template
/// with parts for lists, endnotes, and footnotes, if necessary.
///
// It's a little odd to copy over this xml file, then read and parse it, only to
// append some tags to the end. In the future, it might be better to construct
// this file from scratch. Then we could only include the overrides that are
// strictly necessary (e.g. if there are no images, then we don't need to include
// image filetype overrides)
private func updateContentTypesXML(at docURL: URL,
                                   hasNumbering: Bool,
                                   hasFootnotes: Bool,
                                   hasEndnotes: Bool) throws {
    let contentTypesURL = docURL.appendingPathComponent("[Content_Types].xml")
    let contentTypesData = try Data(contentsOf: contentTypesURL)
    var options = AEXMLOptions()
    options.parserSettings.shouldTrimWhitespace = false
    options.documentHeader.standalone = "yes"
    options.escape = true
    let contentTypesDoc = try AEXMLDocument(xml: contentTypesData, options: options)

    if hasNumbering {
        contentTypesDoc.root.addChild(name: "Override", value: nil, attributes: [
            "PartName": "/word/numbering.xml",
            "ContentType": "application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"
        ])
    }

    if hasFootnotes {
        contentTypesDoc.root.addChild(name: "Override", value: nil, attributes: [
            "PartName": "/word/footnotes.xml",
            "ContentType": "application/vnd.openxmlformats-officedocument.wordprocessingml.footnotes+xml"
        ])
    }

    if hasEndnotes {
        contentTypesDoc.root.addChild(name: "Override", value: nil, attributes: [
            "PartName": "/word/endnotes.xml",
            "ContentType": "application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml"
        ])
    }

    try contentTypesDoc.xmlCompact.write(to: contentTypesURL, atomically: true, encoding: .utf8)
}

private func updateSettingsXML(at settingsURL: URL, endnotePosition: DocXEndnotePosition) throws {
    let settingsData = try Data(contentsOf: settingsURL)
    var options = AEXMLOptions()
    options.parserSettings.shouldTrimWhitespace = false
    options.documentHeader.standalone = "yes"
    options.escape = true

    let settingsDocument = try AEXMLDocument(xml: settingsData, options: options)
    let root = settingsDocument.root

    let endnoteProperties: AEXMLElement
    if let existingEndnoteProperties = root.children.first(where: { $0.name == "w:endnotePr" }) {
        endnoteProperties = existingEndnoteProperties
    } else {
        endnoteProperties = AEXMLElement(name: "w:endnotePr")
        root.addChild(endnoteProperties)
    }

    endnoteProperties.children
        .filter { $0.name == "w:pos" }
        .forEach { $0.removeFromParent() }

    endnoteProperties.addChild(AEXMLElement(name: "w:pos",
                                            value: nil,
                                            attributes: ["w:val": endnotePosition.posValue]))

    try settingsDocument.xmlCompact.write(to: settingsURL, atomically: true, encoding: .utf8)
}

private func emptyRelationshipsDocument() -> AEXMLDocument {
    let root = AEXMLElement(name: "Relationships",
                            value: nil,
                            attributes: ["xmlns": "http://schemas.openxmlformats.org/package/2006/relationships"])
    var options = AEXMLOptions()
    options.parserSettings.shouldTrimWhitespace = false
    options.documentHeader.standalone = "yes"
    options.escape = true
    return AEXMLDocument(root: root, options: options)
}
