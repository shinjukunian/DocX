//
//  UIColor+Components.swift
//  DocX-iOS
//
//  Created by Morten Bertz on 2019/03/11.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation

typealias NSColor = UIColor
typealias NSFont = UIFont
let boldTrait=UIFontDescriptor.SymbolicTraits.traitBold
let italicTrait=UIFontDescriptor.SymbolicTraits.traitItalic

extension UIColor{
    var redComponent:CGFloat{
        var red:CGFloat=0
        self.getRed(&red, green: nil, blue: nil, alpha: nil)
        return red
    }
    
    var blueComponent:CGFloat{
        var blue:CGFloat=0
        self.getRed(nil, green: nil, blue: &blue, alpha: nil)
        return blue
    }
    
    var greenComponent:CGFloat{
        var green:CGFloat=0
        self.getRed(nil, green: &green, blue: nil, alpha: nil)
        return green
    }
}
