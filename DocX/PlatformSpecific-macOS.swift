//
//  NSFont+FamilyName.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/11.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation

#if os(macOS)
import Cocoa

let boldTrait=NSFontDescriptor.SymbolicTraits.bold
let italicTrait=NSFontDescriptor.SymbolicTraits.italic

extension NSColor{
    var hexColorString:String{
        if let rgbColor=self.usingColorSpace(.deviceRGB) {
            return String.init(format: "%02X%02X%02X", Int(rgbColor.redComponent*255), Int(rgbColor.greenComponent*255), Int(rgbColor.blueComponent*255))
        }
        else{
            return "FFFFFF"
        }
        
    }
}
#endif
