//
//  NSAttributedString+DocX.swift
//  DocXWriter
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import ZipArchive

extension NSAttributedString:DocX{
        
    @objc(saveToUrl:error:) public func saveTo(url:URL)throws{
        
        let tempURL=try FileManager.default.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: url, create: true)
        
        defer{
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let docURL=tempURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let attributes=[NSAttributedString.DocumentAttributeKey.documentType:NSAttributedString.DocumentType.officeOpenXML]
        let wrapper=try self.fileWrapper(from: NSRange(location: 0, length: self.length), documentAttributes: attributes)
        try wrapper.write(to: docURL, options: .atomic, originalContentsURL: nil)
        
        if self.containsRubyAnnotations{ // this is the main attribute that is not conserved by the cocoa exporter. there might, potentially, be others
            let docPath=docURL.appendingPathComponent("word").appendingPathComponent("document").appendingPathExtension("xml")
            try FileManager.default.removeItem(at: docPath)
            let xmlData = try self.docXDocument()
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





