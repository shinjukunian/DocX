//
//  DocXWriting.swift
//  DocXWriter
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import AEXML

extension DocX where Self : NSAttributedString{
    
    var pageDef:AEXMLElement{
        let pageDef=AEXMLElement(name: "w:sectPr", value: nil, attributes: ["w:rsidR":"00045791", "w:rsidSect":"004F37A0"])
        
        let size=AEXMLElement(name: "w:pgSz", value: nil, attributes: ["w:w":"11901", "w:h":"16817", "w:code":"9"])
        let margins=AEXMLElement(name: "w:pgMar", value: nil, attributes: ["w:top":"0", "w:right":"403", "w:bottom":"0", "w:left":"442", "w:header":"0", "w:footer":"113", "w:gutter":"0"])
        let cols=AEXMLElement(name: "w:cols", value: nil, attributes: ["w:space":"708"])
        let grid=AEXMLElement(name: "w:docGrid", value: nil, attributes: ["w:type":"lines", "w:linePitch":"360"])
        
        pageDef.addChild(size)
        pageDef.addChild(margins)
        pageDef.addChild(cols)
        pageDef.addChild(grid)
        
        return pageDef
    }
    
    
    fileprivate var paragraphs:[AEXMLElement]{
        let paragraphs=self.paragraphRanges
        
        return paragraphs.map({range in
            let paragraph=ParagraphElement(string: self, range: range)
            return paragraph
        })
        
    }
    
    
    
    func docXDocument()throws ->String{
        var options=AEXMLOptions()
        options.documentHeader.standalone="yes"
        options.escape=false
        options.lineSeparator="\n"
        let root=DocumentRoot()
        let document=AEXMLDocument(root: root, options: options)
        let body=AEXMLElement(name: "w:body")
        root.addChild(body)
        body.addChildren(self.paragraphs)
        body.addChild(pageDef)
        
        
        return document.xmlCompact
    }
}
