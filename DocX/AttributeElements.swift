//
//  FontElement.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation

extension Dictionary where Key == NSAttributedString.Key{
    var runProperties:AEXMLElement{
        let attributesElement=AEXMLElement(name: "w:rPr")
        if let font=self[.font] as? NSFont{
            attributesElement.addChildren(font.attributeElements)
        }
        if let color=self[.foregroundColor] as? NSColor{
            attributesElement.addChild(color.colorElement)
        }
        if let underline=self[.underlineStyle] as? NSUnderlineStyle, let color=self[.foregroundColor] as? NSColor{
            attributesElement.addChild(underline.underlineElement(for: color))
        }
        if let backgroundColor=self[.backgroundColor] as? NSColor{
            attributesElement.addChild(backgroundColor.backgroundColorElement)
        }
        if let strikeThrough=self[.strikethroughStyle] as? NSUnderlineStyle{
            attributesElement.addChild(strikeThrough.strikeThroughElement)
        }

        
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
    
    
    func linkProperties(relationship:LinkRelationship, affectedString:NSAttributedString)->AEXMLElement{
        let hyperlinkElement=AEXMLElement(name: "w:hyperlink ", value: nil, attributes: ["r:id":relationship.relationshipID])
        let runElement=AEXMLElement(name: "w:r", value: nil, attributes: [:])
        hyperlinkElement.addChild(runElement)
        runElement.addChild(self.runProperties)
        runElement.addChild(affectedString.string.element)
        return hyperlinkElement
    }
}




extension NSColor{
    var hexColorString:String{
        return String.init(format: "%02X%02X%02X", Int(self.redComponent*255), Int(self.greenComponent*255), Int(self.blueComponent*255))
    }
    var colorElement:AEXMLElement{
        return AEXMLElement(name: "w:color", value: nil, attributes: ["w:val":self.hexColorString])
    }
    //http://officeopenxml.com/WPtextShading.php
    var backgroundColorElement:AEXMLElement{
        return AEXMLElement(name: "w:shd", value: nil, attributes: ["w:fill":self.hexColorString, "w:val":"clear", "w:color":self.hexColorString])
    }
}

extension String{
    var element:AEXMLElement{
        let textElement=AEXMLElement(name: "w:t", value: self, attributes: ["xml:space":"preserve"])
        return textElement
    }
}


