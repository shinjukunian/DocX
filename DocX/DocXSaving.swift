//
//  DocXSaving.swift
//  DocXWriter
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import ZipArchive

extension DocX{
    
    func saveTo(url:URL)throws{
        guard let blankDocument=Bundle(for: DocumentRoot.self).url(forResource: "blank", withExtension: nil) else{ throw DocXSavingErrors.noBlankDocument}
        let tempURL=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        try FileManager.default.copyItem(at: blankDocument, to: tempURL)
        let docPath=tempURL.appendingPathComponent("word").appendingPathComponent("document").appendingPathExtension("xml")
        let xmlData = try self.docXDocument()
        try xmlData.write(to: docPath, atomically: true, encoding: .utf8)
        let zipURL=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("zip")
        let success=SSZipArchive.createZipFile(atPath: zipURL.path, withContentsOfDirectory: tempURL.path, keepParentDirectory: false)
        guard success == true else{throw DocXSavingErrors.compressionFailed}
        try FileManager.default.removeItem(at: tempURL)
        try FileManager.default.copyItem(at: zipURL, to: url)
        //try FileManager.default.removeItem(at: zipURL)
        
    }
}
