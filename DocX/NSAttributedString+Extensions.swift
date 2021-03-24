//
//  NSAttributedString+Extensions.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/11.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
#if canImport(Cocoa)
import Cocoa
#elseif canImport(UIKit)
import UIKit
#endif

extension NSAttributedString{
    struct ParagraphRange{
        let range: Range<String.Index>
        let seperator:String
        let breakType:BreakType
    }
    
    
    var paragraphRanges:[ParagraphRange]{
        var ranges=[ParagraphRange]()
        self.string.enumerateSubstrings(in: self.string.startIndex..<self.string.endIndex, options: [.byParagraphs, .substringNotRequired], {_, range, rangeIncludingSeperators, _ in
            
            let separatorRange=range.upperBound..<rangeIncludingSeperators.upperBound
            let seperator=self.string[separatorRange]
            let nsRange=NSRange(separatorRange, in: self.string)
            
            let paragraphRange:ParagraphRange
            
            if nsRange.length > 0,
               let breakAttribute=self.attribute(.breakType, at: nsRange.location, effectiveRange: nil) as? BreakType{
                paragraphRange=ParagraphRange(range: range, seperator: String(seperator), breakType: breakAttribute)
            }
            else{
                paragraphRange=ParagraphRange(range: range, seperator: String(seperator), breakType: .wrap)
            }
            ranges.append(paragraphRange)
            
        })
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
