//
//  ParagraphElement.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation

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
            
            let attributesElement=attributes.runProperties
            
            if let ruby=attributes[.ruby]{
                let rubyAnnotation=ruby as! CTRubyAnnotation
                if let element=rubyAnnotation.rubyElement(baseString: affectedSubstring){
                    runElement.addChildren([attributesElement,element])
                }
            }
            else{
                let textElement=affectedText.element
                runElement.addChildren([attributesElement,textElement])
            }
            
            elements.append(runElement)
        })
        
        return elements
    }
}



extension Dictionary where Key == NSAttributedString.Key{
    var runProperties:AEXMLElement{
        let attributesElement=AEXMLElement(name: "w:rPr")
        if let font=self[.font] as? NSFont{
            attributesElement.addChildren(font.attributeElements)
        }
        if let color=self[.foregroundColor] as? NSColor{
            attributesElement.addChild(color.colorElement)
        }
//        if let underline=self[.underlineStyle] as? NSUnderlineStyle{
//            
//        }
        return attributesElement
    }
    
    func rubyAnnotationRunProperties(scaleFactor:CGFloat)->AEXMLElement{
        let element=self.runProperties
        if let font=self[.font] as? NSFont{
            let size=Int(font.pointSize*scaleFactor*2)
            let sizeElement=AEXMLElement(name: "w:sz", value: nil, attributes: ["w:val":String(size)])
            element.addChild(sizeElement)
            
        }
        return element
    }
}

