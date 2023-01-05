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
    func writeDocX_builtin(to url: URL,
                           options: DocXOptions = DocXOptions(),
                           configuration: DocXConfiguration = DocXConfiguration()) throws{
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
        
        // If DocXConfiguration contains a valid stylesURL, then copy that into the docx
        if let srcStylesURL = configuration.stylesURL {
            let destStylesURL = wordSubdirURL.appendingPathComponent("styles").appendingPathExtension("xml")
            try FileManager.default.copyItem(at: srcStylesURL, to: destStylesURL)
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
        if configuration.stylesURL != nil {
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
        
        let linkRelations=self.prepareLinks(linkXML: linkDocument, mediaURL: mediaURL)
        let updatedLinks=linkDocument.xmlCompact
        try updatedLinks.write(to: linkURL, atomically: true, encoding: .utf8)
        
        let xmlData = try self.docXDocument(linkRelations: linkRelations,
                                            configuration: configuration)
        
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
