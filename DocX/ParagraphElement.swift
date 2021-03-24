//
//  ParagraphElement.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
#if canImport(Cocoa)
import Cocoa
#elseif canImport(UIKit)
import UIKit
#endif
import AEXML

class ParagraphElement:AEXMLElement{
    
    fileprivate override init(name: String, value: String? = nil, attributes: [String : String] = [String : String]()) {
        fatalError()
    }
    
    let linkRelations:[LinkRelationship]
    
    init(string:NSAttributedString, range:NSAttributedString.ParagraphRange, linkRelations:[LinkRelationship]) {
        self.linkRelations=linkRelations
        super.init(name: "w:p", value: nil, attributes: ["rsidR":"00045791", "w:rsidRDefault":"008111DF"])
        self.addChildren(self.buildRuns(string: string, range: range))
    }
    
    
    fileprivate func buildRuns(string:NSAttributedString, range:NSAttributedString.ParagraphRange)->[AEXMLElement]{
        
        var elements=[AEXMLElement]()
        let subString=string.attributedSubstring(from: NSRange(range.range, in: string.string))
        
        guard subString.length>0 else{return [AEXMLElement]()}
        
        if let paragraphStyle=subString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle{
            elements.append(paragraphStyle.paragraphElements)
        }
        
        subString.enumerateAttributes(in: NSRange(location: 0, length: subString.length), options: [], using: {attributes, effectiveRange, stop in
            
            let affectedSubstring=subString.attributedSubstring(from: effectiveRange)
            
            if let link=attributes[.link] as? URL, let relationShip=self.linkRelations.first(where: {$0.linkURL == link}){
                elements.append(attributes.linkProperties(relationship: relationShip, affectedString: affectedSubstring))
            }
            else{
                let runElement=AEXMLElement(name: "w:r", value: nil, attributes: [:])
                
                let affectedText=affectedSubstring.string
                
                let attributesElement=attributes.runProperties
                
                if let ruby=attributes[.ruby]{
                    let rubyAnnotation=ruby as! CTRubyAnnotation // no idea how to avoid force casting here
                    if let element=rubyAnnotation.rubyElement(baseString: affectedSubstring){
                        runElement.addChildren([attributesElement,element])
                    }
                }
                else{
                    let textElement=affectedText.element
                    runElement.addChildren([attributesElement,textElement])
                }
                
                elements.append(runElement)
            }
        })
        
        if let breakElement=range.breakType.breakElement{
            elements.append(breakElement)
        }
        
        return elements
    }
}



extension BreakType{
    var breakElement:AEXMLElement?{
        switch self {
        case .wrap:
            return nil
        case .page, .column:
            let runElement=AEXMLElement(name: "w:r", value: nil, attributes: [:])
            runElement.addChild(AEXMLElement(name: "w:br", value: nil, attributes: self.breakElementAttributes))
            return runElement
        }
    }
    
    var breakElementAttributes:[String:String]{
        switch self {
        case .wrap:
            return [:]
        case .column:
            return ["w:type":"column"]
        case .page:
            return ["w:type":"page"]
        }
    }
    
}
