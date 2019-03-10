//
//  NSAttributedString+DocX.swift
//  DocXWriter
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation

extension NSAttributedString:DocX{}

extension NSAttributedString{
    var paragraphRanges:[Range<String.Index>]{
        var ranges=[Range<String.Index>]()
        self.string.enumerateSubstrings(in: self.string.startIndex..<self.string.endIndex, options: [.byParagraphs], {_, range, rangeIncludingSeperators, _ in
            ranges.append(range)
        })
        return ranges
    }
}





