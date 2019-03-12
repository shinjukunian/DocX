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
        paragraphStyleElement.addChildren([self.alignmentElement,
                                           self.spacingElement,
                                           self.indentationElement].compactMap({$0}))
        
        return paragraphStyleElement
    }
    
    var alignmentElement:AEXMLElement?{
        let element=AEXMLElement(name: "w:jc", value: nil, attributes: ["w:val":self.alignment.attributeValue])
        return element
    }
    
    //http://officeopenxml.com/WPspacing.php
    var spacingElement:AEXMLElement?{
        var attributes=[String:String]()
        
        if self.paragraphSpacingBefore > 0{
            attributes["w:before"]=String(Int(self.paragraphSpacingBefore*20))
        }
        if self.paragraphSpacing > 0{
            attributes["w:after"]=String(Int(self.paragraphSpacing*20))
        }
        if self.lineHeightMultiple > 0{
            attributes["w:lineRule"]="auto"
            attributes["w:line"]=String(Int(self.lineHeightMultiple*240))
        }
        if self.lineSpacing > 0{
            attributes["w:lineRule"]="exact"
            attributes["w:line"]=String(Int(self.lineSpacing*20))
        }
        
        guard attributes.isEmpty == false else {return nil}
        return AEXMLElement(name: "w:spacing", value: nil, attributes: attributes)
    }
    
    var indentationElement:AEXMLElement?{ // this is conceptually very different and this complicated
        var attributes=[String:String]()
        if self.headIndent > 0 || self.firstLineHeadIndent > 0{
            let delta=self.headIndent-self.firstLineHeadIndent
            switch delta{
            case _ where delta == 0:
                attributes["w:start"]=String(Int(self.headIndent * 20))
            case _ where delta > 0: //hanging, 2nd line further indented than first
                attributes["w:start"]=String(Int(self.headIndent * 20))
                attributes["w:hanging"]=String(Int(delta * 20))
            case _ where delta < 0:
                attributes["w:start"]=String(Int(self.headIndent * 20))
                attributes["w:firstLine"]=String(Int(-delta * 20))
            default:
                break
            }
        }
        /* this isnt really compatible with how cocoa is handling tail indents, in the NSTextView, the indent is from the leading margin
         word, howver, want the distance from the trailing margin, we don't know that, unless we know the page size
         the tailindent could alo be negative, which means it is from the trailing margin. wehn using the standar ruler views to manipulate the indents, however, the value appears to be positive throughout
         the Cocoa TextKit exporter ignores these attributes entirely
         */
        if self.tailIndent < 0{
            attributes["w:end"]=String(Int(abs(self.tailIndent) * 20))
        }

        guard attributes.isEmpty == false else {return nil}
        return AEXMLElement(name: "w:ind", value: nil, attributes: attributes)
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
