//
//  DocXWriter.swift
//  
//
//  Created by Morten Bertz on 2021/03/24.
//

import Foundation

public class DocXWriter{
    
    /// Convenience function to write an array of NSAttributedString to separate pages in a .docx file
    /// - Parameters:
    ///   - pages: an array of NSAttributedStrings. A page break fill be inserted after each page.
    ///   - url: The destination of the resulting .docx, e.g. ```myfile.docx```
    ///   - options: an optional instance of `DocXOptions`. This allows you to specify metadata for the document.
    ///   - configuration: an optional instance of `DocXConfiguration` that allows you to control the docx output.
    /// - Throws: Throws errors for I/O.
    public class func write(pages:[NSAttributedString],
                            to url:URL,
                            options:DocXOptions = DocXOptions(),
                            configuration: DocXConfiguration = DocXConfiguration()) throws {
        guard let first=pages.first else {return}
        let result=NSMutableAttributedString(attributedString: first)
        let pageSeperator=NSAttributedString(string: "\r", attributes: [.breakType:BreakType.page])
        
        for page in pages.dropFirst(){
            result.append(pageSeperator)
            result.append(page)
        }
        
        try result.writeDocX(to: url, options: options, configuration: configuration)
    }
}
