//
//  NSAttributedString+DocX.swift
//  DocXWriter
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import ZipArchive
import AEXML


#if os(macOS)

// this version is based on in initially using the TextKit docx Writer. Since it doesnt support furigana or links, we might go entirely with our own implementatuion
extension NSAttributedString:DocX{
    @objc public func writeDocX(to url: URL) throws {
        try self.writeDocX(to: url, useBuiltIn: true)
    }
    
        
    @objc public func writeDocX(to url: URL, useBuiltIn:Bool = true) throws{
        
        let tempURL=try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)
        
        defer{
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let docURL=tempURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let attributes=[NSAttributedString.DocumentAttributeKey.documentType:NSAttributedString.DocumentType.officeOpenXML]
        let wrapper=try self.fileWrapper(from: NSRange(location: 0, length: self.length), documentAttributes: attributes)
        try wrapper.write(to: docURL, options: .atomic, originalContentsURL: nil)
        
        if self.containsRubyAnnotations || useBuiltIn == false{ // this is the main attribute that is not conserved by the cocoa exporter. there might, potentially, be others
            let docPath=docURL.appendingPathComponent("word").appendingPathComponent("document").appendingPathExtension("xml")
            let linkURL=docURL.appendingPathComponent("word").appendingPathComponent("_rels").appendingPathComponent("document.xml.rels")
            let linkData=try Data(contentsOf: linkURL)
            var options=AEXMLOptions()
            options.parserSettings.shouldTrimWhitespace=false
            options.documentHeader.standalone="yes"
            let linkDocument=try AEXMLDocument(xml: linkData, options: options)
            let linkRelations=self.prepareLinks(linkXML: linkDocument)
            let updatedLinks=linkDocument.xmlCompact
            try updatedLinks.write(to: linkURL, atomically: true, encoding: .utf8)
            
            try FileManager.default.removeItem(at: docPath)
            let xmlData = try self.docXDocument(linkRelations: linkRelations)
            
            try xmlData.write(to: docPath, atomically: true, encoding: .utf8)
        }

        let zipURL=tempURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("zip")
        let success=SSZipArchive.createZipFile(atPath: zipURL.path, withContentsOfDirectory: docURL.path, keepParentDirectory: false)
        guard success == true else{throw DocXSavingErrors.compressionFailed}
    
        do{
            try FileManager.default.copyItem(at: zipURL, to: url)
        }
        catch let error as NSError{
            if error.code == 516{ // file exisis, we overwrite relentlessly 
                try FileManager.default.removeItem(at: url)
                try FileManager.default.copyItem(at: zipURL, to: url)
            }
            else{
                throw error
            }
        }
    }
    
}

#endif





