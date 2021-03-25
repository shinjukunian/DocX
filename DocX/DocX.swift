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
    func docXDocument(linkRelations:[DocumentRelationship])throws ->String
    func writeDocX(to url:URL)throws
    func prepareLinks(linkXML:AEXMLDocument, mediaURL:URL)->[DocumentRelationship]
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
    static let breakType = NSAttributedString.Key.init("com.telethon.docx.attributedstringkey.break")
}

/// Encapsulates different break types in a document.
public enum BreakType: String, Equatable{
    /// The text continues in the next line
    case wrap
    /// The text continues on the next page
    case page
    /// The text continues in the next folumn for multicolumn text. If there is only one column or the column is the last column, it continues on the next page.
    case column
}
