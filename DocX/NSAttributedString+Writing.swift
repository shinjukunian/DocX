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
    func writeDocX_builtin(to url: URL, options:DocXOptions = DocXOptions()) throws{
        let tempURL=try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)
        
        defer{
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let docURL=tempURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        guard let blankURL=Bundle.blankDocumentURL else{throw DocXSavingErrors.noBlankDocument}
        try FileManager.default.copyItem(at: blankURL, to: docURL)

        let docPath=docURL.appendingPathComponent("word").appendingPathComponent("document").appendingPathExtension("xml")
        
        let linkURL=docURL.appendingPathComponent("word").appendingPathComponent("_rels").appendingPathComponent("document.xml.rels")
        let mediaURL=docURL.appendingPathComponent("word").appendingPathComponent("media", isDirectory: true)
        let propsURL=docURL.appendingPathComponent("docProps").appendingPathComponent("core").appendingPathExtension("xml")
        
        
        let linkData=try Data(contentsOf: linkURL)
        var docOptions=AEXMLOptions()
        docOptions.parserSettings.shouldTrimWhitespace=false
        docOptions.documentHeader.standalone="yes"
        
        // Enable escaping so that reserved characters, like < & >, don't
        // result in an invalid docx file
        // See: https://github.com/shinjukunian/DocX/issues/24
        docOptions.escape = true
        
        let linkDocument=try AEXMLDocument(xml: linkData, options: docOptions)
        let linkRelations=self.prepareLinks(linkXML: linkDocument, mediaURL: mediaURL)
        let updatedLinks=linkDocument.xmlCompact
        try updatedLinks.write(to: linkURL, atomically: true, encoding: .utf8)
        
        let xmlData = try self.docXDocument(linkRelations: linkRelations)
        
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
