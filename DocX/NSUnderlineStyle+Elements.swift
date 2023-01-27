
//
//  URL+Element.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/12.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

import AEXML

extension NSUnderlineStyle{
    
    var elementValue:String{
        let val:String
        switch self {
        case _ where self.contains(.byWord):
            val = "words"
        case _ where self.contains(.single):
            val = "single"
        case _ where self.contains(.double):
            val = "double"
        case _ where self.contains(.patternDash):
            val = "dash"
        case _ where self.contains(.patternDot):
            val = "dotted"
        case _ where self.contains(.patternDashDot):
            val = "dotDash"
        case _ where self.contains(.patternDashDotDot):
            val = "dotDotDash"
        default:
            val = "none"
        }
        return val
    }
    
    func underlineElement(for color:NSColor?)->AEXMLElement{
        // Always add the underline value, which determines the underline style
        var attributes = ["w:val": self.elementValue]
        
        // If color is specified, include that too
        if let color = color {
            let colorString = color.hexColorString
            attributes["w:color"] = colorString
        }
        
        return AEXMLElement(name: "w:u", value: nil, attributes: attributes)
    }
    
    var strikeThroughElement:AEXMLElement{
        if self.contains(.double){
            return AEXMLElement(name: "w:dstrike", value: nil, attributes: ["w:val":"true"])
        }
        else{
            return AEXMLElement(name: "w:strike", value: nil, attributes: ["w:val":"true"])
        }
    }
    
}
