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


