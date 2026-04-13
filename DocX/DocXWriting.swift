//
//  DocXWriting.swift
//  DocXWriter
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import AEXML
import Foundation
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
import MobileCoreServices
fileprivate typealias NSImage = UIImage
#elseif canImport(AppKit)
import AppKit
#endif

enum DocXWriteImageError: Error {
    case noImageData
    case invalidImageData
}

@available(OSX 10.11, *)
extension DocX where Self : NSAttributedString{
    
    func pageDef(options: DocXOptions?) -> AEXMLElement{
        let pageDef=AEXMLElement(name: "w:sectPr", value: nil, attributes: [:])
        
        // Add any footnote or endnote section properties
        pageDef.addChildren(noteSectionProperties(options: options))
        
        if self.usesVerticalForms{
            let vertical=AEXMLElement(name: "w:textDirection", value: nil, attributes: ["w:val":"tbRl"])
            pageDef.addChild(vertical)
        }
        
        if let page=options?.pageDefinition{
            pageDef.addChildren(page.pageElements)
        }
        
        //these elements are added for by word, but not by the cocoa docx exporter. word then falls back to the page setup defined by the print settings of the machine. this seems useful
        
//        let size=AEXMLElement(name: "w:pgSz", value: nil, attributes: ["w:w":"11901", "w:h":"16817", "w:code":"9"])
//        let margins=AEXMLElement(name: "w:pgMar", value: nil, attributes: ["w:top":"0", "w:right":"403", "w:bottom":"0", "w:left":"442", "w:header":"0", "w:footer":"113", "w:gutter":"0"])
//        let cols=AEXMLElement(name: "w:cols", value: nil, attributes: ["w:space":"708"])
//        let grid=AEXMLElement(name: "w:docGrid", value: nil, attributes: ["w:type":"lines", "w:linePitch":"360"])
//        
//        pageDef.addChild(size)
//        pageDef.addChild(margins)
//        pageDef.addChild(cols)
//        pageDef.addChild(grid)
        
        return pageDef
    }

    func noteSectionProperties(options: DocXOptions?) -> [AEXMLElement] {
        var properties = [AEXMLElement]()

        if let footnotePr = noteSectionProperty(name: "w:footnotePr",
                                                numberFormat: options?.footnoteNumberFormat,
                                                numberRestart: options?.footnoteNumberRestart) {
            properties.append(footnotePr)
        }

        if let endnotePr = noteSectionProperty(name: "w:endnotePr",
                                               numberFormat: options?.endnoteNumberFormat,
                                               numberRestart: options?.endnoteNumberRestart) {
            properties.append(endnotePr)
        }

        return properties
    }

    private func noteSectionProperty(name: String,
                                     numberFormat: DocXNoteNumberFormat?,
                                     numberRestart: DocXNoteNumberRestart?) -> AEXMLElement? {
        guard numberFormat != nil || numberRestart != nil else {
            return nil
        }

        let property = AEXMLElement(name: name)

        if let numberFormat {
            property.addChild(AEXMLElement(name: "w:numFmt",
                                           value: nil,
                                           attributes: ["w:val": numberFormat.numFmtValue]))
        }

        if let numberRestart {
            property.addChild(AEXMLElement(name: "w:numRestart",
                                           value: nil,
                                           attributes: ["w:val": numberRestart.numRestartValue]))
        }

        return property
    }
    
    
    /// Builds `<w:p>` elements for the supplied paragraph ranges.
    func buildParagraphs(paragraphRanges:[ParagraphRange],
                         linkRelations:[DocumentRelationship],
                         options:DocXOptions,
                         leadingNoteBodyReferenceKind: ParagraphElement.NoteReferenceKind? = nil) -> [AEXMLElement]{
        return paragraphRanges.enumerated().map({ idx, range in
            // When exporting a note body, `leadingNoteBodyReferenceKind` inserts Word's
            // required `w:footnoteRef` or `w:endnoteRef` marker at the start of the
            // note. That marker should only appear in the first paragraph of the note
            // body, so we only pass the value through for index `0`.
            let paragraph=ParagraphElement(string: self,
                                           range: range,
                                           linkRelations: linkRelations,
                                           options: options,
                                           leadingNoteBodyReferenceKind: (idx == 0) ? leadingNoteBodyReferenceKind : nil)
            return paragraph
        })
    }
    
    func docXDocument(linkRelations:[DocumentRelationship] = [DocumentRelationship](),
                      options:DocXOptions = DocXOptions())throws ->String{
        try docXDocument(sectionStrings: [self],
                         linkRelations: linkRelations,
                         options: options)
    }

    func docXDocument(sectionStrings: [NSAttributedString],
                      linkRelations:[DocumentRelationship] = [DocumentRelationship](),
                      options:DocXOptions = DocXOptions()) throws -> String {
        var xmlOptions=AEXMLOptions()
        xmlOptions.documentHeader.standalone="yes"
        
        // Enable escaping so that reserved characters, like < & >, don't
        // result in an invalid docx file
        // See: https://github.com/shinjukunian/DocX/issues/18
        xmlOptions.escape = true
        
        xmlOptions.lineSeparator="\n"
        let root=DocumentRoot()
        let document=AEXMLDocument(root: root, options: xmlOptions)
        let body=AEXMLElement(name: "w:body")
        root.addChild(body)

        for (index, sectionString) in sectionStrings.enumerated() {
            var paragraphs = sectionString.buildParagraphs(paragraphRanges: sectionString.documentParagraphRanges,
                                                           linkRelations: linkRelations,
                                                           options: options)
            // Insert an explicit section break after every section except the
            // last one. The final section properties are written separately as
            // the trailing `<w:sectPr>` on the document body.
            if index < sectionStrings.count - 1 {
                sectionString.addSectionBreak(to: &paragraphs, options: options)
            }
            body.addChildren(paragraphs)
        }

        body.addChild(pageDef(options: options))
        return document.xmlCompact
    }
    
    func addSectionBreak(to paragraphs: inout [AEXMLElement], options: DocXOptions) {
        // For now, always create a Section Break (Next Page)
        // There are other types of section breaks, but we don't support them yet
        let sectionPropertiesElement = AEXMLElement(name: "w:sectPr")
        sectionPropertiesElement.addChild(AEXMLElement(name: "w:type",
                                                       value: nil,
                                                       attributes: ["w:val": "nextPage"]))
        sectionPropertiesElement.addChildren(noteSectionProperties(options: options))

        // Intermediate section breaks must live on a paragraph's properties.
        // Reuse the last paragraph when one exists; otherwise create an empty
        // paragraph solely to carry the `w:sectPr` for an otherwise empty section.
        if let lastParagraph = paragraphs.last {
            let paragraphPropertiesElement: AEXMLElement
            if let existingParagraphProperties = lastParagraph.children.first(where: { $0.name == "w:pPr" }) {
                paragraphPropertiesElement = existingParagraphProperties
            } else {
                // w:pPr must be the first child of w:p
                // Remove existing children, add w:pPr, then re-add them
                let existingChildren = lastParagraph.children
                existingChildren.forEach { $0.removeFromParent() }
                paragraphPropertiesElement = AEXMLElement(name: "w:pPr")
                lastParagraph.addChild(paragraphPropertiesElement)
                lastParagraph.addChildren(existingChildren)
            }
            paragraphPropertiesElement.addChild(sectionPropertiesElement)
        } else {
            let paragraph = AEXMLElement(name: "w:p",
                                         value: nil,
                                         attributes: [:])
            let paragraphPropertiesElement = AEXMLElement(name: "w:pPr")
            paragraphPropertiesElement.addChild(sectionPropertiesElement)
            paragraph.addChild(paragraphPropertiesElement)
            paragraphs.append(paragraph)
        }
    }

    func lastRelationshipIdIndex(linkXML: AEXMLDocument) -> Int {
        let relationships=linkXML["Relationships"]
        let presentIds=relationships.children.map({$0.attributes}).compactMap({$0["Id"]}).sorted(by: {s1, s2 in
            return s1.compare(s2, options: [.numeric], range: nil, locale: nil) == .orderedAscending
        })
        
        let lastIdIDX:Int
        if let lastID=presentIds.last?.trimmingCharacters(in: .letters){
            lastIdIDX=Int(lastID) ?? 0
        }
        else{
            lastIdIDX=0
        }
        
        return lastIdIDX
    }
   
    func prepareLinks(linkXML: AEXMLDocument,
                      mediaURL:URL,
                      options:DocXOptions,
                      mediaFilenamePrefix: String = "") -> [DocumentRelationship] {
        var linkURLS=[URL]()
        
        let imageRelationships = prepareImages(linkXML: linkXML,
                                               mediaURL: mediaURL,
                                               options: options,
                                               mediaFilenamePrefix: mediaFilenamePrefix)
        
        self.enumerateAttribute(.link, in: NSRange(location: 0, length: self.length), options: [.longestEffectiveRangeNotRequired], using: {attribute, _, stop in
            if let link=attribute as? URL{
                linkURLS.append(link)
            }
        })
        guard linkURLS.count > 0 else {return imageRelationships}
        
        let lastIdIDX = lastRelationshipIdIndex(linkXML: linkXML)
        
        let linkRelationShips=linkURLS.enumerated().map({(arg)->LinkRelationship in
            let (idx, url) = arg
            let newID="rId\(lastIdIDX+1+idx)"
            let relationShip=LinkRelationship(relationshipID: newID, linkURL: url)
            return relationShip
        })
        
        let relationships=linkXML["Relationships"]
        relationships.addChildren(linkRelationShips.map({$0.element}))
        
        return linkRelationShips + imageRelationships
    }
    
    // Since all images live in `word/media`, use `mediaFilenamePrefix` to
    // prevent name collisions (e.g. for images in endnotes and footnotes).
    func prepareImages(linkXML: AEXMLDocument,
                       mediaURL:URL,
                       options:DocXOptions,
                       mediaFilenamePrefix: String = "") -> [DocumentRelationship]{
        var attachements=[NSTextAttachment]()
        self.enumerateAttribute(.attachment, in: NSRange(location: 0, length: self.length), options: [.longestEffectiveRangeNotRequired], using: {attribute, _, stop in
            if let link=attribute as? NSTextAttachment{
                attachements.append(link)
            }
        })
        
        if #available(macOS 12.0, iOS 15.0, *) {
            self.enumerateAttribute(.imageURL, in: NSRange(location: 0, length: self.length), options: [.longestEffectiveRangeNotRequired], using: {attribute, _, stop in
                if let link=attribute as? URL,
                   let wrapper=try? FileWrapper(url: link){
                    let attachement=NSTextAttachment(fileWrapper: wrapper)
                    attachements.append(attachement)
                }
            })
        }
            
        guard attachements.count > 0 else {return [ImageRelationship]()}
        
        let relationships=linkXML["Relationships"]
        let presentIds=relationships.children.map({$0.attributes}).compactMap({$0["Id"]}).sorted(by: {s1, s2 in
            return s1.compare(s2, options: [.numeric], range: nil, locale: nil) == .orderedAscending
        })
        
        let lastIdIDX:Int
        
        if let lastID=presentIds.last?.trimmingCharacters(in: .letters){
            lastIdIDX=Int(lastID) ?? 0
        }
        else{
            lastIdIDX=0
        }
        
        if ((try? mediaURL.checkResourceIsReachable()) ?? false) == false{
            try? FileManager.default.createDirectory(at: mediaURL, withIntermediateDirectories: false, attributes: [:])
        }
        
        let imageRelationShips=attachements.enumerated().compactMap({(idx, attachement)->ImageRelationship? in
            // Construct the new relationship identifier
            let newID="rId\(lastIdIDX+1+idx)"

            // Attempt to write the image
            if let destURL = try? writeImage(attachment: attachement,
                                             mediaURL: mediaURL,
                                             newID: newID,
                                             fileNamePrefix: mediaFilenamePrefix) {
                // We successfully wrote the image
                // Return the image relationship
                return ImageRelationship(relationshipID: newID,
                                         linkURL: destURL,
                                         attachement: attachement,
                                         pageDefinition: options.pageDefinition)
            } else {
                // Something went wrong
                return nil
            }
        })
        
        relationships.addChildren(imageRelationShips.map({$0.element}))
        
        return imageRelationShips
    }
    
    private func writeImage(attachment: NSTextAttachment,
                            mediaURL: URL,
                            newID: String,
                            fileNamePrefix: String) throws -> URL {
        // If there's no image data, return
        guard var imageData = attachment.imageData else {
            throw DocXWriteImageError.noImageData
        }
        
        // See if the text attachment's `fileType` is known
        // If it is, we'll find a valid file extension
        let fileExtension: String?
        if let fileType = attachment.fileType,
           let ext = imageFileExtension(fileType: fileType) {
            // The `fileType` is known so we'll use the returned file extension
            fileExtension = ext
        } else if let image = NSImage(data: imageData),
                  let pngData = image.pngData {
            // The `fileType` isn't known, but we were able to convert
            // the image data to PNG data. Use that instead.
            imageData = pngData
            fileExtension = "png"
        } else {
            fileExtension = nil
        }
        
        // If the image data is invalid – e.g. we don't have a valid extension –
        // there's nothing to do
        guard let fileExtension = fileExtension else {
            throw DocXWriteImageError.invalidImageData
        }

        // Construct the path we'll write to. `fileNamePrefix` is empty
        // for main-document media, but note parts pass prefixes like
        // `footnotes-` and `endnotes-` to keep filenames unique
        let destURL = mediaURL.appendingPathComponent(fileNamePrefix + newID).appendingPathExtension(fileExtension)
        
        // Attempt to write the image
        try imageData.write(to: destURL, options: .atomic)
        
        // Return the URL of the image
        return destURL
    }
    
    /// Returns the file extension for a known `fileType`
    ///
    /// ** When adding a new supported fileType to this function,
    ///    remember to add a corresponding entry for the extension
    ///    and mimetype to [Content_Types].xml**
    private func imageFileExtension(fileType:String) -> String? {
        if (fileType == UTType.gif.identifier) {
            return "gif"
        } else if (fileType == UTType.jpeg.identifier) {
            return "jpeg"
        } else if (fileType == UTType.png.identifier) {
            return "png"
        } else if (fileType == UTType.tiff.identifier) {
            return "tiff"
        } else if (fileType == UTType.pdf.identifier) {
            return "pdf"
        } else if (fileType == "com.adobe.photoshop-image") {
            return "psd"
        } else {
            return nil
        }
    }
}

extension LinkRelationship{
    
    //<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="https://www.rakuten-sec.co.jp/ITS/V_ACT_Login.html" TargetMode="External"/>
    var element:AEXMLElement{
        return AEXMLElement(name: "Relationship", value: nil, attributes: ["Id":self.relationshipID, "Type":"http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink", "Target":self.linkURL.absoluteString, "TargetMode":"External"])
    }
    
}
