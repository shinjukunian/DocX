//
//  NSAttributedString+DocX-iOS.swift
//  DocX-iOS
//
//  Created by Morten Bertz on 2019/03/11.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation


extension NSAttributedString:DocX{
    
    /// Saves the attributed string to the destination URL
    /// - Parameter url: the destination URL, e.g. ```myfolder/mydocument.docx```
    /// - Throws: Throws for I/O related errors
    @objc public func writeDocX(to url: URL) throws{
        try self.writeDocX_builtin(to: url)
    }
    
    /// Saves the attributed string to the destination URL
    /// - Parameters:
    ///     - url: the destination URL, e.g. ```myfolder/mydocument.docx```
    ///     - options: an optional instance of `DocXOptions`. This allows you to specify metadata for the document.
    /// - Throws: Throws for I/O related errors
    public func writeDocX(to url: URL, options:DocXOptions = DocXOptions()) throws{
        try self.writeDocX_builtin(to: url, options: options)
    }
}



