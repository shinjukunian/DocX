//
//  ParagraphElement.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import AEXML

class ParagraphElement:AEXMLElement{
    
    fileprivate override init(name: String, value: String? = nil, attributes: [String : String] = [String : String]()) {
        fatalError()
    }
    
    let linkRelations:[DocumentRelationship]
    
    init(string:NSAttributedString,
         range:NSAttributedString.ParagraphRange,
         linkRelations:[DocumentRelationship],
         options:DocXOptions) {
        self.linkRelations=linkRelations
        super.init(name: "w:p", value: nil, attributes: ["rsidR":"00045791", "w:rsidRDefault":"008111DF"])
        self.addChildren(self.buildRuns(string: string, range: range, options: options))
    }
    
    
    fileprivate func buildRuns(string:NSAttributedString,
                               range:NSAttributedString.ParagraphRange,
                               options:DocXOptions) -> [AEXMLElement]{
        
        var elements=[AEXMLElement]()
        let subString=string.attributedSubstring(from: range.range)
                
        // Create an element for holding the paragraph properties
        let paragraphPropertiesElement = AEXMLElement(name:"w:pPr")
        
        // If there's an NSParagraphStyle for this paragraph, get its
        // paragraph property elements
        if subString.length > 0,
           let paragraphStyle=subString.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle{
            paragraphPropertiesElement.addChildren(paragraphStyle.paragraphElements)
        }
        
        // If there's a paragraph style name for this paragraph, add it
        if let paragraphStyleElement = range.styleElement {
            paragraphPropertiesElement.addChild(paragraphStyleElement)
        }

        // If the paragraph properties element contains any properties, add it
        if paragraphPropertiesElement.children.count > 0 {
            elements.append(paragraphPropertiesElement)
        }
        
        // If the sub string is empty, then we can append the break (if necessary)
        // and return early
        guard subString.length > 0 else {
            if let breakElement=range.breakType.breakElement{
                elements.append(breakElement)
            }
            return elements

        }
        
        subString.enumerateAttributes(in: NSRange(location: 0, length: subString.length), options: [], using: {attributes, effectiveRange, stop in
            
            let affectedSubstring=subString.attributedSubstring(from: effectiveRange)
            
            if let link=attributes[.link] as? URL,
               let relationship=self.linkRelations.first(where: {$0.linkURL == link}) as? LinkRelationship{
                elements.append(attributes.linkProperties(relationship: relationship, affectedString: affectedSubstring))
            }
            else if let imageAttachement=attributes[.attachment] as? NSTextAttachment,
                    let relationship=self.linkRelations.first(where: {rel in
                guard let rel=rel as? ImageRelationship else {return false}
                return rel.attachement == imageAttachement
            }) as? ImageRelationship{
                elements.append(relationship.attributeElement)
            }
            else if #available(macOS 12.0,iOS 15.0, *) ,
                    let imageURLAttachement=attributes[.imageURL] as? URL,
                    let relationship=self.linkRelations.first(where: {rel in
                        guard let rel=rel as? ImageRelationship else {return false}
                        return rel.attachement.fileWrapper?.matchesContents(of: imageURLAttachement) ?? false
                    }) as? ImageRelationship{
                elements.append(relationship.attributeElement)
            }
            
            else{
                let runElement=AEXMLElement(name: "w:r", value: nil, attributes: [:])
                
                let affectedText=affectedSubstring.string
                
                let attributesElement=attributes.runProperties
                
                if let styleConfiguration = options.styleConfiguration {
                    // If the font family shouldn't be output, remove it from the run properties.
                    // We do this here – rather than ignore the NSFont when runProperties are
                    // generated – since the font is used to determine other font properties
                    // that we want to keep (e.g. bold, italics, size, etc.).
                    //
                    // So, if requested, remove the FontElement that specifies the family
                    if !styleConfiguration.outputFontFamily,
                       let fontElement = attributesElement.children.first(where: { $0 is FontElement }) {
                        fontElement.removeFromParent()
                    }
                }
                
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
