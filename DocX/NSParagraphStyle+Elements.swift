//
//  NSParagraphStyle+Elements.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/12.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation

extension NSParagraphStyle{
    
    var paragraphElements:AEXMLElement{
        let paragraphStyleElement=AEXMLElement(name: "w:pPr")
        paragraphStyleElement.addChildren([self.alignmentElement].compactMap({$0}))
        return paragraphStyleElement
    }
    
    var alignmentElement:AEXMLElement?{
        let element=AEXMLElement(name: "w:jc", value: nil, attributes: ["w:val":self.alignment.attributeValue])
        return element
    }
    
}

extension NSTextAlignment{
    //http://officeopenxml.com/WPalignment.php
    var attributeValue:String{
        switch self {
        case .center:
            return "center"
        case .justified:
            return "both"
        case .left:
            return "start"
        case .right:
            return "end"
        default:
            return "start"
        }
    }
}
