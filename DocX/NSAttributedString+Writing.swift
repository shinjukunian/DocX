//
//  NSAttributedString+DocX.swift
//  
//
//  Created by Morten Bertz on 2021/03/23.
//

import Foundation
import ZIPFoundation
import AEXML


extension NSAttributedString{
    func writeDocX_builtin(to url: URL, options: DocXOptions = DocXOptions()) throws{
        let tempURL=try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)
        
        defer{
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let docURL=tempURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        guard let blankURL=Bundle.blankDocumentURL else{throw DocXSavingErrors.noBlankDocument}
        try FileManager.default.copyItem(at: blankURL, to: docURL)

        let wordSubdirURL = docURL.appendingPathComponent("word")
        let docPath = wordSubdirURL.appendingPathComponent("document").appendingPathExtension("xml")
        let linkURL = wordSubdirURL.appendingPathComponent("_rels").appendingPathComponent("document.xml.rels")
        let mediaURL = wordSubdirURL.appendingPathComponent("media", isDirectory: true)
        let propsURL=docURL.appendingPathComponent("docProps").appendingPathComponent("core").appendingPathExtension("xml")
        
        // If the DocXOptions contains a styles configuration with a valid styles XML document,
        // then write that into the docx
        let configStylesXMLDocument = options.styleConfiguration?.stylesXMLDocument
        if let configStylesXMLDocument = configStylesXMLDocument {
            // Construct the path for the `styles.xml` file
            let stylesURL = wordSubdirURL.appendingPathComponent("styles").appendingPathExtension("xml")
            
            // Compact the styles XML and write it
            let compactStylesXML = configStylesXMLDocument.xmlCompact
            try compactStylesXML.write(to: stylesURL, atomically: true, encoding: .utf8)
        }
        
        let linkData=try Data(contentsOf: linkURL)
        var docOptions=AEXMLOptions()
        docOptions.parserSettings.shouldTrimWhitespace=false
        docOptions.documentHeader.standalone="yes"
        
        // Enable escaping so that reserved characters, like < & >, don't
        // result in an invalid docx file
        // See: https://github.com/shinjukunian/DocX/issues/24
        docOptions.escape = true
        
        let linkDocument=try AEXMLDocument(xml: linkData, options: docOptions)
        
        // The `document.xml.rels` files should include a link to styles.xml
        if configStylesXMLDocument != nil {
            // Construct the attributes for the Relationship to the styles filename
            // This Relationship needs a unique id (one greater than the last "rId{#}")
            // and always points to "styles.xml"
            let newRelationshipIndex = self.lastRelationshipIdIndex(linkXML: linkDocument) + 1
            let newIdString = "rId\(newRelationshipIndex)"
            let attrs = ["Id": newIdString,
                         "Type": "http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles",
                         "Target": "styles.xml"]
            
            // Add the Relationship
            linkDocument.root.addChild(name: "Relationship", value: nil, attributes: attrs)
        }
        
        let linkRelations=self.prepareLinks(linkXML: linkDocument, mediaURL: mediaURL, options: options)
        let updatedLinks=linkDocument.xmlCompact
        try updatedLinks.write(to: linkURL, atomically: true, encoding: .utf8)
        
        let xmlData = try self.docXDocument(linkRelations: linkRelations,
                                            options: options)
        
        try xmlData.write(to: docPath, atomically: true, encoding: .utf8)
        
        let metaData=options.xml.xmlCompact
        try metaData.write(to: propsURL, atomically: true, encoding: .utf8)

        let zipURL=tempURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("zip")
        try FileManager.default.zipItem(at: docURL, to: zipURL, shouldKeepParent: false, compressionMethod: .deflate, progress: nil)
        
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
