//
//  ParagraphElement.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import AEXML

class ParagraphElement:AEXMLElement{
    
    fileprivate override init(name: String, value: String? = nil, attributes: [String : String] = [String : String]()) {
        fatalError()
    }
    
    init(string:NSAttributedString, range:Range<String.Index>) {
        super.init(name: "w:p", value: nil, attributes: ["rsidR":"00045791", "w:rsidRDefault":"008111DF"])
        self.addChildren(self.buildRuns(string: string, range: range))
    }
    
    
    fileprivate func buildRuns(string:NSAttributedString, range:Range<String.Index>)->[AEXMLElement]{
        
        let runElement=AEXMLElement(name: "w:r", value: nil, attributes: [:])
        let subString=string.attributedSubstring(from: NSRange(range, in: self.string))
        guard subString.length>0 else{return [AEXMLElement]()}
        
        let attributes=subString.attributes(at: 0, effectiveRange: nil)
        let attributesElement=AEXMLElement(name: "w:rPr")
        if let font=attributes[.font] as? NSFont{
            attributesElement.addChildren(font.attributeElements)
        }
        
        let textElement=AEXMLElement(name: "w:t", value: subString.string, attributes: [:])
        
        runElement.addChildren([attributesElement,textElement])
        
        return [runElement]
    }
}
