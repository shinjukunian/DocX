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
        
        if self.usesVerticalForms{
            let vertical=AEXMLElement(name: "w:textDirection", value: nil, attributes: ["w:val":"tbRl"])
            pageDef.addChild(vertical)
        }
        
        //these elements are added for by word, but not by the cocoa docx exporter. word then falls back to the page setup defined by the print settings of the machine. this seems useful
        
//        let size=AEXMLElement(name: "w:pgSz", value: nil, attributes: ["w:w":"11901", "w:h":"16817", "w:code":"9"])
//        let margins=AEXMLElement(name: "w:pgMar", value: nil, attributes: ["w:top":"0", "w:right":"403", "w:bottom":"0", "w:left":"442", "w:header":"0", "w:footer":"113", "w:gutter":"0"])
//        let cols=AEXMLElement(name: "w:cols", value: nil, attributes: ["w:space":"708"])
//        let grid=AEXMLElement(name: "w:docGrid", value: nil, attributes: ["w:type":"lines", "w:linePitch":"360"])
//        
//        pageDef.addChild(size)
//        pageDef.addChild(margins)
//        pageDef.addChild(cols)
//        pageDef.addChild(grid)
        
        return pageDef
    }
    
    
    func buildParagraphs(paragraphRanges:[ParagraphRange], linkRelations:[LinkRelationship]) -> [AEXMLElement]{
        return paragraphRanges.map({range in
            let paragraph=ParagraphElement(string: self, range: range, linkRelations: linkRelations)
            return paragraph
        })
    }
    
    func docXDocument(linkRelations:[LinkRelationship] = [LinkRelationship]())throws -> String{
        var options=AEXMLOptions()
        options.documentHeader.standalone="yes"
        options.escape=false
        options.lineSeparator="\n"
        let root=DocumentRoot()
        let document=AEXMLDocument(root: root, options: options)
        let body=AEXMLElement(name: "w:body")
        root.addChild(body)
        body.addChildren(self.buildParagraphs(paragraphRanges: self.paragraphRanges, linkRelations: linkRelations))
        body.addChild(pageDef)
        return document.xmlCompact
    }
   
    func prepareLinks(linkXML: AEXMLDocument) -> [LinkRelationship] {
        var linkURLS=[URL]()
        self.enumerateAttribute(.link, in: NSRange(location: 0, length: self.length), options: [.longestEffectiveRangeNotRequired], using: {attribute, _, stop in
            if let link=attribute as? URL{
                linkURLS.append(link)
            }
        })
        guard linkURLS.count > 0 else {return [LinkRelationship]()}
        let relationships=linkXML["Relationships"]
        let presentIds=relationships.children.map({$0.attributes}).compactMap({$0["Id"]}).sorted(by: {s1, s2 in
            return s1.compare(s2, options: [.numeric], range: nil, locale: nil) == .orderedAscending
        })
        guard let lastID=presentIds.last?.trimmingCharacters(in: .letters), let lastIdIDX=Int(lastID) else{return [LinkRelationship]()}
        
        let linkRelationShips=linkURLS.enumerated().map({(arg)->LinkRelationship in
            let (idx, url) = arg
            let newID="rId\(lastIdIDX+1+idx)"
            let relationShip=LinkRelationship(relationshipID: newID, linkURL: url)
            return relationShip
        })
        
        relationships.addChildren(linkRelationShips.map({$0.element}))
        
        return linkRelationShips
    }
    
}

extension LinkRelationship{
    
    //<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="https://www.rakuten-sec.co.jp/ITS/V_ACT_Login.html" TargetMode="External"/>
    var element:AEXMLElement{
        return AEXMLElement(name: "Relationship", value: nil, attributes: ["Id":self.relationshipID, "Type":"http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink", "Target":self.linkURL.absoluteString, "TargetMode":"External"])
    }
    
    
}
