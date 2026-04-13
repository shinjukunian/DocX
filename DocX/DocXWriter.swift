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
    ///   - url: The destination of the resulting .docx, e.g. `myfile.docx`
    ///   - options: an optional instance of `DocXOptions`. This allows you to specify metadata for the document and customize docx output.
    /// - Throws: Throws errors for I/O.
    public class func write(pages: [NSAttributedString],
                            to url: URL,
                            options: DocXOptions = DocXOptions()) throws {
        guard let first = pages.first else {
            return
        }
        
        let result = NSMutableAttributedString(attributedString: first)
        let separatorString = NSAttributedString(string: "\r", attributes: [.breakType: BreakType.page])

        for page in pages.dropFirst() {
            result.append(separatorString)
            result.append(page)
        }

        try result.writeDocX(to: url, options: options)
    }

    /// Convenience function to write an array of attributed strings as separate
    /// document sections in a single .docx file.
    /// - Parameters:
    ///   - sections: an array of section contents in document order
    ///   - url: The destination of the resulting .docx, e.g. `myfile.docx`
    ///   - options: an optional instance of `DocXOptions`. This allows you to specify metadata for the document and customize docx output
    /// - Throws: Throws errors for I/O.
    public class func write(sections: [NSAttributedString],
                            to url: URL,
                            options: DocXOptions = DocXOptions()) throws {
        guard !sections.isEmpty else { return }
        try sections.writeDocXSections(to: url, options: options)
    }
}
