//
//  File.swift
//  
//
//  Created by Morten Bertz on 2021/07/28.
//

import Foundation
import AEXML


/// Metadata and output settings for docx creation
public struct DocXOptions{
    
    // Metadata
    //
    
    /// The author of the document. Defaults to 'DocX'. This value is also used to set the `lastModifiedBy` value.
    public var author: String="DocX"
    
    /// The title of the document. Defaults to an empty string.
    public var title: String=""
    
    /// The subject of the document of the document. Defaults to an empty string.
    public var subject: String=""
    
    /// A description of the document of the document. Defaults to an empty string.
    public var description: String=""
    
    /// An array of keywords describing the content of the document.
    public var keywords: [String] = [String]()
    
    /// The creation date of the document. Defaults to now.
    public var createdDate: Date = Date()
    
    /// The modification date of the document. Defaults to now.
    public var modifiedDate: Date = Date()
    
    // Output settings
    //
    
    /// An optional configuration object for style output
    public var styleConfiguration: DocXStyleConfiguration?
    
    
    public init(){}
    
    let attributes: [String:String] = ["xmlns:cp": "http://schemas.openxmlformats.org/package/2006/metadata/core-properties",
                                     "xmlns:dc": "http://purl.org/dc/elements/1.1/",
                                     "xmlns:dcterms": "http://purl.org/dc/terms/",
                                     "xmlns:dcmitype": "http://purl.org/dc/dcmitype/",
                                     "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance"]
    
    var xml:AEXMLDocument{
        
        var options=AEXMLOptions()
        options.documentHeader.standalone="yes"
        options.documentHeader.encoding="UTF-8"
        
        // Enable escaping so that reserved characters, like < & >, don't
        // result in an invalid docx file
        // See: https://github.com/shinjukunian/DocX/issues/18
        options.escape = true
        
        options.lineSeparator="\n"

        let root=AEXMLElement(name: "cp:coreProperties", value: nil, attributes: attributes)
        let doc=AEXMLDocument(root: root, options: options)
        
        let dateFormatter=ISO8601DateFormatter()
        dateFormatter.formatOptions=[.withInternetDateTime]
        
        root.addChildren([AEXMLElement(name: "dc:title", value: title, attributes: [String:String]()),
                         AEXMLElement(name: "dc:subject", value: subject, attributes: [String:String]()),
                         AEXMLElement(name: "dc:creator", value: author, attributes: [String:String]()),
                         AEXMLElement(name: "cp:keywords", value: keywords.joined(separator: ","), attributes: [String:String]()),
                         AEXMLElement(name: "dc:description", value: description, attributes: [String:String]()),
                         AEXMLElement(name: "cp:lastModifiedBy", value: author, attributes: [String:String]()),
                         AEXMLElement(name: "cp:revision", value: "1", attributes: [String:String]()),
                         AEXMLElement(name: "dcterms:created", value: dateFormatter.string(from: createdDate), attributes: ["xsi:type":"dcterms:W3CDTF"]),
                         AEXMLElement(name: "dcterms:modified", value: dateFormatter.string(from: modifiedDate), attributes: ["xsi:type":"dcterms:W3CDTF"]),
        ])
        
        
        return doc
    }
    
    
}
