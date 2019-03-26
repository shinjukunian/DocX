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
            if let strokeWidth=self[.strokeWidth] as? CGFloat,
                strokeWidth != 0,
                let font=self[.font] as? NSFont{
                attributesElement.addChildren(self.outlineProperties(strokeWidth: strokeWidth, font:font))
            }
            else{
                attributesElement.addChild(color.colorElement)
            }
        }else if let strokeWidth=self[.strokeWidth] as? CGFloat, //stroke only without any fill color
            strokeWidth != 0,
            let font=self[.font] as? NSFont{
            attributesElement.addChildren(self.outlineProperties(strokeWidth: strokeWidth, font:font))
        }
        
        if let style=self[.underlineStyle] as? Int, let color=self[.foregroundColor] as? NSColor{
            let underline=NSUnderlineStyle(rawValue: style)
            attributesElement.addChild(underline.underlineElement(for: color))
        }
        
        if let backgroundColor=self[.backgroundColor] as? NSColor{
            attributesElement.addChild(backgroundColor.backgroundColorElement)
        }
        
        if let style=self[.strikethroughStyle] as? Int{
            let strikeThrough=NSUnderlineStyle(rawValue: style)
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
    
    
    
    /*
     we could use w:outline as well, but that doesnt allow us to specify the width and the fill color (this is what cocoa does)
     http://officeopenxml.com/WPtextFormatting.php
     https://docs.microsoft.com/en-us/previous-versions/office/developer/office-2010/ee863804%28v%3Doffice.14%29
     */
    func outlineProperties(strokeWidth:CGFloat, font:NSFont)->[AEXMLElement]{ //we need the font becasue the stroke width is in percent of the font size
        let strokeColor:NSColor
        let fillColor:NSColor
        
        if strokeWidth > 0{ //stroke only
            strokeColor=(self[.strokeColor] as? NSColor ?? self[.foregroundColor] as? NSColor) ?? NSColor.black
            fillColor=self[.backgroundColor] as? NSColor ?? NSColor.white // we only have rgb, so wa cant define transparent fills
        }
        else{//stroke and fill
            strokeColor=(self[.strokeColor] as? NSColor ?? self[.foregroundColor] as? NSColor) ?? NSColor.black
            fillColor=self[.foregroundColor] as? NSColor ?? NSColor.black
        }
        
        let fontSize=font.pointSize
        let strokeWidth=abs(fontSize * strokeWidth / 100)
        let wordStrokeWidth=Int(strokeWidth * 12700) //magic number that word uses for 1 pnt, it is apparently in EMUs
        let colorElement=fillColor.colorElement
        let outlineElement=AEXMLElement(name: "w14:textOutline", value: nil, attributes: ["w14:cap":"flat", "w14:cmpd":"sng", "w14:algn":"ctr","w14:w":String(wordStrokeWidth)])
        let fillElement=AEXMLElement(name: "w14:solidFill")
        outlineElement.addChild(fillElement)
        let strokeColorElement=AEXMLElement(name: "w14:srgbClr", value: nil, attributes: ["w14:val":strokeColor.hexColorString])
        fillElement.addChild(strokeColorElement)
        let dashElement=AEXMLElement(name: "w14:prstDash", value: nil, attributes: ["w14:val":"solid"])
        outlineElement.addChild(dashElement)
        let lineCapElement=AEXMLElement(name: "w14:round")
        outlineElement.addChild(lineCapElement)
        
        return [colorElement,outlineElement]
        
    }
    
}




extension NSColor{
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


