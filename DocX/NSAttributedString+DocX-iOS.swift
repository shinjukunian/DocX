//
//  NSAttributedString+DocX-iOS.swift
//  DocX-iOS
//
//  Created by Morten Bertz on 2019/03/11.
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
        guard let blankURL=Bundle(for: DocumentRoot.self).url(forResource: "blank", withExtension: nil) else{throw DocXSavingErrors.noBlankDocument}
        try FileManager.default.copyItem(at: blankURL, to: docURL)

        let docPath=docURL.appendingPathComponent("word").appendingPathComponent("document").appendingPathExtension("xml")
        try FileManager.default.removeItem(at: docPath)
        let xmlData = try self.docXDocument()
        try xmlData.write(to: docPath, atomically: true, encoding: .utf8)

        let zipURL=tempURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("zip")
        let success=SSZipArchive.createZipFile(atPath: zipURL.path, withContentsOfDirectory: docURL.path, keepParentDirectory: false)
        guard success == true else{throw DocXSavingErrors.compressionFailed}

        try FileManager.default.copyItem(at: zipURL, to: url)
    }
    
}
