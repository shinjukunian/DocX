//
//  DocX.swift
//  DocXWriter
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import AEXML

#if canImport(AppKit)
import Cocoa
#elseif canImport(UIKit)
import UIKit
#endif

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

struct ImageRelationship:DocumentRelationship{
    let relationshipID:String
    let linkURL:URL
    let attachement:NSTextAttachment
}

protocol DocX{
    func docXDocument(linkRelations:[DocumentRelationship])throws ->String
    func writeDocX(to url:URL)throws
    func prepareLinks(linkXML:AEXMLDocument, mediaURL:URL)->[DocumentRelationship]
}

public let docXUTIType="org.openxmlformats.wordprocessingml.document"



