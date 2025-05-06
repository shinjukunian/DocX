//
//  NSAttributedString+DocX.swift
//  DocXWriter
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import ZIPFoundation
import AEXML


#if os(macOS)

// this version is based on in initially using the TextKit docx Writer. Since it doesnt support furigana or links, we might go entirely with our own implementatuion
extension NSAttributedString{
    
    
    /// TextKit on macOS comes with its own, limited .docx exporter. This function allows you to select the _builtin_ or the _DocX_ exporter. The builtin exporter lacks support for some attributes (furigana, links, images).
    /// - Parameters:
    ///   - url: the destination url, e.g. ```myfolder/mydocument.docx```.
    ///   - useBuiltIn: if _true_, the TextKit exporter will be used. If _false_ *DocX* will be used. For some attributes (furigana, links), *DocX* will fall back to the custom exporter.
    /// - Throws: Throws for I/O errors.
    @objc public func writeDocX(to url: URL, useBuiltIn:Bool = true) throws{
        
        if useBuiltIn == false{
            try writeDocX_builtin(to: url)
            return
        }
        
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
            let mediaURL=docURL.appendingPathComponent("word").appendingPathComponent("media", isDirectory: true)
            
            let linkData=try Data(contentsOf: linkURL)
            var options=AEXMLOptions()
            options.parserSettings.shouldTrimWhitespace=false
            options.documentHeader.standalone="yes"
            
            // Enable escaping so that reserved characters, like < & >, don't
            // result in an invalid docx file
            // See: https://github.com/shinjukunian/DocX/issues/24
            options.escape = true

            let linkDocument=try AEXMLDocument(xml: linkData, options: options)
            let linkRelations=self.prepareLinks(linkXML: linkDocument, mediaURL: mediaURL, options: DocXOptions())
            let updatedLinks=linkDocument.xmlCompact
            try updatedLinks.write(to: linkURL, atomically: true, encoding: .utf8)
            
            try FileManager.default.removeItem(at: docPath)
            let xmlData = try self.docXDocument(linkRelations: linkRelations)
            
            try xmlData.write(to: docPath, atomically: true, encoding: .utf8)
        }

        let zipURL=tempURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("zip")

        try FileManager.default.zipItem(at: docURL, to: zipURL, shouldKeepParent: false, compressionMethod: .deflate, progress: nil)
    
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





