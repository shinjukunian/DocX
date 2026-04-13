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
        let numberingId: Int?
        let numberingLevel: Int?
        let listStyle: DocXListStyle?
        let footnoteBodyId: Int?
        let endnoteBodyId: Int?
        
        var styleElement: AEXMLElement? {
            if let styleId = styleId {
                return AEXMLElement(name: "w:pStyle",
                                    value: nil,
                                    attributes: ["w:val": styleId])
            } else {
                return nil
            }
        }
        
        /// Returns a `<w:numPr>` element if this paragraph has list numbering info.
        var numberingElement: AEXMLElement? {
            guard let numId = numberingId else {
                return nil
            }
            
            let level = numberingLevel ?? 0
            let numPr = AEXMLElement(name: "w:numPr")
            numPr.addChild(AEXMLElement(name: "w:ilvl",
                                         value: nil,
                                         attributes: ["w:val": "\(level)"]))
            numPr.addChild(AEXMLElement(name: "w:numId",
                                         value: nil,
                                         attributes: ["w:val": "\(numId)"]))
            return numPr
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
               
        // The numbering ID to use when we encounter a new list
        // (that doesn't continue from a previous list)
        var textListNumberingID = 0

        // Tracks the last `numberingId` encountered for a list of a particular style
        var textListNumberingTracker: [DocXListStyle: Int] = [:]
        
        // Whether we are currently in a list
        var isInList = false
        
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
            
            // Determine whether footnote or endnote attributes are present
            let footnoteBodyId = self.attribute(.footnoteBodyId,
                                                at: paragraphStyleRange.location,
                                                effectiveRange: nil) as? Int
            let endnoteBodyId = self.attribute(.endnoteBodyId,
                                               at: paragraphStyleRange.location,
                                               effectiveRange: nil) as? Int
            
            // Get the NSParagraphStyle attribute so we can check for list items
            var numberingId : Int?
            var numberingLevel: Int?
            var listStyle: DocXListStyle?
            if let paragraphStyle = self.attribute(.paragraphStyle,
                                                   at: paragraphStyleRange.location,
                                                   effectiveRange: nil) as? NSParagraphStyle {
                // Does this paragraph belong to any lists?
                let lists = paragraphStyle.textLists
                if lists.count > 0 {
                    // `lists` represents the nested lists containing the paragraph,
                    // in order from outermost to innermost. Therefore, the indent
                    // level is just the length (less one because it's zero based)
                    numberingLevel = lists.count - 1
                    
                    // Get the innermost list to determine the listStyle
                    if let textList = lists.last {
                        listStyle = DocXListStyle(markerFormat: textList.markerFormat)
                    }
                    
                    if !isInList,
                       let listStyle = listStyle {
                        // If we weren't already in a list, we are now
                        isInList = true

                        // Determine if this list is a continuation from a previous list
                        //
                        // If the `startingItemNumber` is greater than 1, then
                        // we'll assume this list continues on from a previous
                        // one of the same style
                        //
                        // Note that we don't enforce that `startingItemNumber`
                        // must be one larger than the last item number of the
                        // previous list: if it's greater than 1, we'll
                        // just assume it's a continuation.
                        if numberingLevel == 0,
                           let firstTextList = lists.first,
                           firstTextList.startingItemNumber > 1,
                           let prevNumberingIdForStyle = textListNumberingTracker[listStyle] {
                            // Reuse the previous numberingId
                            numberingId = prevNumberingIdForStyle
                        } else {
                            // Increment the numberingId
                            textListNumberingID += 1
                            
                            // Save the numberingId for this particular style
                            textListNumberingTracker[listStyle] = textListNumberingID
                        }
                    }
                    
                    // If we haven't assigned a numberingId yet, use `textListNumberingID`
                    if numberingId == nil {
                        numberingId = textListNumberingID
                    }
                }
                else{
                    isInList = false
                }
            } else {
                // No paragraph style at all, therefore we aren't in a list
                isInList = false
            }
            
            
            // Create a ParagraphRange and add it to our list
            let paragraphRange = ParagraphRange(range: substringRange,
                                                breakType: breakType,
                                                styleId: paragraphStyleId,
                                                numberingId: numberingId,
                                                numberingLevel: numberingLevel,
                                                listStyle: listStyle,
                                                footnoteBodyId: footnoteBodyId,
                                                endnoteBodyId: endnoteBodyId)
            ranges.append(paragraphRange)
        }
        return ranges
    }

    /// Returns the paragraph ranges for paragraphs that should be in the main document
    /// This excludes footnote and endnote body text
    var documentParagraphRanges: [ParagraphRange] {
        paragraphRanges.filter { range in
            range.footnoteBodyId == nil &&
            range.endnoteBodyId == nil
        }
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
