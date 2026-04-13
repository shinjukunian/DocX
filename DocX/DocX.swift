//
//  DocX.swift
//  DocXWriter
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import AEXML

enum DocXSavingErrors:Error{
    case noBlankDocument
    case compressionFailed
    case duplicateNoteId(kind: String, id: Int)
}

protocol DocumentRelationship {
    var relationshipID:String {get}
    var linkURL:URL {get}
}

struct LinkRelationship:DocumentRelationship{
    let relationshipID:String
    let linkURL:URL
}

protocol DocX{
    func docXDocument(linkRelations:[DocumentRelationship],
                      options:DocXOptions) throws ->String
    func writeDocX(to url:URL)throws
    func writeDocX(to url:URL, options:DocXOptions) throws
    func prepareLinks(linkXML:AEXMLDocument, mediaURL:URL, options:DocXOptions, mediaFilenamePrefix: String)->[DocumentRelationship]
}

public let docXUTIType="org.openxmlformats.wordprocessingml.document"


public extension NSAttributedString.Key{
    /**
     A custom attribute to enable manual page breaking.
     
    For example:
    ```
     let text=NSMutableAttributedString(string: *some string*, attributes:[:])
     let pageSeperator=NSAttributedString(string: "\r", attributes:[.breakType : BreakType.page])
     text.append(pageSeperator)
     ```
     will result in a page break after *some string*
    */
    static let breakType = NSAttributedString.Key("com.telethon.docx.attributedstringkey.break")
    
    /// A custom attribute that specifies the styleId to use for an entire paragraph
    static let paragraphStyleId = NSAttributedString.Key("com.telethon.docx.attributedstringkey.paragraphStyleId")
    
    /// A custom attribute that specifies the styleId to use for characters
    static let characterStyleId = NSAttributedString.Key("com.telethon.docx.attributedstringkey.characterStyleId")
    
    /// A custom attribute that specifies the id for a footnote reference
    static let footnoteReferenceId = NSAttributedString.Key("com.telethon.docx.attributedstringkey.footnoteReferenceId")

    /// A custom attribute that specifies the id for an endnote reference
    static let endnoteReferenceId = NSAttributedString.Key("com.telethon.docx.attributedstringkey.endnoteReferenceId")

    /// A custom attribute that assigns a paragraph to a footnote body
    static let footnoteBodyId = NSAttributedString.Key("com.telethon.docx.attributedstringkey.footnoteBodyId")

    /// A custom attribute that assigns a paragraph to an endnote body
    static let endnoteBodyId = NSAttributedString.Key("com.telethon.docx.attributedstringkey.endnoteBodyId")
}

/// Encapsulates different break types in a document.
public enum BreakType: String, Equatable {
    /// The text continues in the next line
    case wrap
    /// The text continues on the next page
    case page
    /// The text continues in the next folumn for multicolumn text. If there is only one column or the column is the last column, it continues on the next page.
    case column
}
