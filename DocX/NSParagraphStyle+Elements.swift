//
//  NSParagraphStyle+Elements.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/12.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import AEXML

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension NSParagraphStyle{
    
    var paragraphElements: [AEXMLElement] {
        return [self.alignmentElement,
                self.spacingElement,
                self.indentationElement].compactMap({$0})
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
    
    // A value of 0 is often used to indicate that no attributes should be
    // output. See, for instance, `spacingElement` above.
    //
    // For indentation, though, setting values to zero can be valid.
    // We don't want to break existing clients, so we've introduced a
    // variable, `zeroIndent`, which can be used to force indentation to
    // zero, when desired.
    //
    public static var zeroIndent: CGFloat {
        // Using a value of 0.01 for allows us to continue using the >0 checks.
        // It's small enough (.2 twips) that even if someone specified an
        // indent of 0.01 explicitly, setting the indent to 0 would be equivalent.
        return 0.01
    }

    var indentationElement:AEXMLElement?{ // this is conceptually very different and this complicated
        var attributes=[String:String]()
        
        // indentation in Word is stored in twips (a twentieth of a point)
        let twipsPerPoint = CGFloat(20)
        
        if self.headIndent > 0 || self.firstLineHeadIndent > 0 {
            let headIndent = self.headIndent == NSParagraphStyle.zeroIndent ? 0 : self.headIndent
            let firstLineHeadIndent = self.firstLineHeadIndent == NSParagraphStyle.zeroIndent ? 0 : self.firstLineHeadIndent
            
            // Determine whether this paragraph uses hanging indentation (i.e.
            // the first line isn't indented, but the following lines are)
            let delta = headIndent - firstLineHeadIndent
            if (delta > 0) {
                // Hanging indentation
                attributes["w:start"]=String(Int(headIndent * twipsPerPoint))
                attributes["w:hanging"]=String(Int(delta * twipsPerPoint))
            } else {
                // "Normal" indentation
                attributes["w:start"]=String(Int(headIndent * twipsPerPoint))
                attributes["w:firstLine"]=String(Int(-delta * twipsPerPoint))
            }
        }
        
        /* this isnt really compatible with how cocoa is handling tail indents, in the NSTextView, the indent is from the leading margin
         word, howver, want the distance from the trailing margin, we don't know that, unless we know the page size
         the tailindent could alo be negative, which means it is from the trailing margin. wehn using the standar ruler views to manipulate the indents, however, the value appears to be positive throughout
         the Cocoa TextKit exporter ignores these attributes entirely
         */
        if self.tailIndent < 0{
            attributes["w:end"]=String(Int(abs(self.tailIndent) * twipsPerPoint))
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
