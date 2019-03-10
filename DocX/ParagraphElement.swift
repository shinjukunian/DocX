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
        
        var elements=[AEXMLElement]()
        let subString=string.attributedSubstring(from: NSRange(range, in: self.string))
        guard subString.length>0 else{return [AEXMLElement]()}
        
        
        
        subString.enumerateAttributes(in: NSRange(location: 0, length: subString.length), options: [], using: {attributes, effectiveRange, stop in
            
            let runElement=AEXMLElement(name: "w:r", value: nil, attributes: [:])
            let affectedSubstring=subString.attributedSubstring(from: effectiveRange)
            let affectedText=affectedSubstring.string
            
            let attributesElement=AEXMLElement(name: "w:rPr")
            if let font=attributes[.font] as? NSFont{
                attributesElement.addChildren(font.attributeElements)
            }
            if let color=attributes[.foregroundColor] as? NSColor{
                attributesElement.addChild(color.colorElement)
            }
            
            if let ruby=attributes[NSAttributedString.Key(kCTRubyAnnotationAttributeName as String)]{
                let rubyAnnotation=ruby as! CTRubyAnnotation
                if let element=rubyAnnotation.rubyElement(baseString: affectedSubstring){
                    runElement.addChildren([attributesElement,element])
                }
            }
            else{
                let textElement=AEXMLElement(name: "w:t", value: affectedText, attributes: [:])
                runElement.addChildren([attributesElement,textElement])
            }
            
            elements.append(runElement)
        })
        
        return elements
    }
}



