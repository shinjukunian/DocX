//
//  NSTextAttachement + Extensions.swift
//  DocX
//
//  Created by Morten Bertz on 2021/03/23.
//  Copyright © 2021 telethon k.k. All rights reserved.
//

import Foundation
#if canImport(AppKit)
import Cocoa
#elseif canImport(UIKit)
import UIKit
#endif

extension NSTextAttachment{
    
    struct Size {
        let width:Int
        let height:Int
    }
    
    @available(OSX 10.11, *)
    var imageData: Data?{
        if let imageData=self.image?.pngData{
            return imageData
        }
        else{
            return self.contents
        }
    }
    
    var extentInEMU:Size{
        let width=self.image?.size.width ?? 0
        let height=self.image?.size.height ?? 0
        let emuPerInch=CGFloat(914400)
        let dpi=CGFloat(72)
        let emuWidth=width/dpi*emuPerInch
        let emuHeight=height/dpi*emuWidth
        return Size(width: Int(emuWidth), height: Int(emuHeight))
        
    }
    
}
