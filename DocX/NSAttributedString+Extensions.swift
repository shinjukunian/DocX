//
//  NSAttributedString+Extensions.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/11.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import AEXML

#if canImport(Cocoa)
import Cocoa
#elseif canImport(UIKit)
import UIKit
#endif

extension NSAttributedString{
    struct ParagraphRange{
        let range: NSRange
        let breakType: BreakType
        let styleId: String?
        
        var styleElement: AEXMLElement? {
            if let styleId = styleId {
                return AEXMLElement(name: "w:pStyle",
                                    value: nil,
                                    attributes: ["w:val": styleId])
            } else {
                return nil
            }
        }
    }
    
    
    var paragraphRanges:[ParagraphRange] {
        var ranges = [ParagraphRange]()
        
        // Make sure we are operating on an NSString, and not a String, to
        // prevent unnecessary bridging. That bridging, and resulting String
        // allocation, can significantly affect speed for long strings that
        // contain separators
        let string = self.string as NSString
        let fullRange = NSMakeRange(0, string.length)
                
        string.enumerateSubstrings(in: fullRange, options: [.byParagraphs, .substringNotRequired])
        { _, substringRange, enclosingRange, _ in
            // Determine the range of the paragraph separator
            let substringRangeMax = NSMaxRange(substringRange)
            let enclosingRangeMax = NSMaxRange(enclosingRange)
            let separatorRange = NSMakeRange(substringRangeMax,
                                             enclosingRangeMax - substringRangeMax)
            
            // If the paragraph ends with a separator that has a valid BreakType
            // attribute, remember it for later
            let breakType: BreakType
            if separatorRange.length > 0,
               let breakAttribute = self.attribute(.breakType,
                                                   at: separatorRange.location,
                                                   effectiveRange: nil) as? BreakType {
                breakType = breakAttribute
            } else {
                // Otherwise, use the default break type of Wrap
                breakType = .wrap
            }
            
            // Determine whether a `paragraphStyleId` is specified for the *entire*
            // paragraph. If it isn't, then we won't apply the style at all.
            //
            let paragraphStyleId: String?
            var longestEffectiveRange = NSRange()
            // If the paragraph doesn't have any text (i.e. it's a blank line),
            // we still may want to apply a paragraph style. If that's the case,
            // our range will be the `enclosingRange` (the paragraph break);
            // otherwise, just use the substring range.
            let paragraphStyleRange = (substringRange.length == 0) ? enclosingRange : substringRange
            if let styleId = self.attribute(.paragraphStyleId,
                                            at: paragraphStyleRange.location,
                                            longestEffectiveRange: &longestEffectiveRange,
                                            in: paragraphStyleRange) as? String,
               longestEffectiveRange == paragraphStyleRange {
                paragraphStyleId = styleId
            } else {
                // Either no `paragraphStyleId` was set, or it doesn't apply
                // to an entire paragraph
                paragraphStyleId = nil
            }
            
            // Create a ParagraphRange and add it to our list
            let paragraphRange = ParagraphRange(range: substringRange,
                                                breakType: breakType,
                                                styleId: paragraphStyleId)
            ranges.append(paragraphRange)
        }
        return ranges
    }
    
    var usesVerticalForms:Bool{
        var vertical=false
        
        self.enumerateAttribute(.verticalForms, in: NSRange(location: 0, length: self.length), options: [.longestEffectiveRangeNotRequired], using: {attribute, _, stop in
            if let attribute = attribute as? Bool,attribute == true{
                vertical=true
                stop.pointee=true
            }
        })
        self.enumerateAttribute(.verticalGlyphForm, in: NSRange(location: 0, length: self.length), options: [.longestEffectiveRangeNotRequired], using: {attribute, _, stop in
            if let attribute = attribute as? Bool,attribute == true{
                vertical=true
                stop.pointee=true
            }
        })
        
        return vertical
    }
    
    var containsRubyAnnotations:Bool{
        var hasRuby=false
        self.enumerateAttribute(.ruby, in: NSRange(location: 0, length: self.length), options: [.longestEffectiveRangeNotRequired], using: {attribute, _, stop in
            if attribute != nil{
                hasRuby=true
                stop.pointee=true
            }
        })
        return hasRuby
    }
}


public extension NSAttributedString.Key{
    static let ruby=NSAttributedString.Key(kCTRubyAnnotationAttributeName as String)
    static let verticalForms=NSAttributedString.Key(kCTVerticalFormsAttributeName as String)
}
