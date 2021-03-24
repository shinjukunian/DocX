//
//  NSAttributedString+DocX.swift
//  
//
//  Created by Morten Bertz on 2021/03/23.
//

import Foundation
import ZipArchive
import AEXML


extension NSAttributedString{
    func writeDocX_builtin(to url: URL) throws{
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
        let linkData=try Data(contentsOf: linkURL)
        var options=AEXMLOptions()
        options.parserSettings.shouldTrimWhitespace=false
        options.documentHeader.standalone="yes"
        let linkDocument=try AEXMLDocument(xml: linkData, options: options)
        let linkRelations=self.prepareLinks(linkXML: linkDocument, mediaURL: mediaURL)
        let updatedLinks=linkDocument.xmlCompact
        try updatedLinks.write(to: linkURL, atomically: true, encoding: .utf8)
        
        let xmlData = try self.docXDocument(linkRelations: linkRelations)
        
        try xmlData.write(to: docPath, atomically: true, encoding: .utf8)

        let zipURL=tempURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("zip")
        let success=SSZipArchive.createZipFile(atPath: zipURL.path, withContentsOfDirectory: docURL.path, keepParentDirectory: false)
        guard success == true else{throw DocXSavingErrors.compressionFailed}

        try FileManager.default.copyItem(at: zipURL, to: url)
    }
}