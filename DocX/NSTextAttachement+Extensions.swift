//
//  NSTextAttachement + Extensions.swift
//  DocX
//
//  Created by Morten Bertz on 2021/03/23.
//  Copyright © 2021 telethon k.k. All rights reserved.
//

import Foundation

#if canImport(UIKit)
import UIKit
#else
fileprivate typealias UIImage = NSImage
import Cocoa
#endif

import AEXML

// a hackish overlay for watchOS to make the symbol available
#if os(watchOS)
struct NSTextAttachment: Equatable {
    var image:UIImage?
    var contents:Data?
    var fileWrapper:FileWrapper?
    init() {
        fatalError()
    }
}
#endif

extension NSTextAttachment{
    
    struct Size {
        let width:Int
        let height:Int
        
        var extentAttribute:AEXMLElement{
            return AEXMLElement(name: "wp:extent", value: nil, attributes: self.extentAttributes)
        }
        var extentAttributes:[String:String]{
            return ["cx":String(width), "cy":String(height)]
        }
    }
    
    @available(OSX 10.11, *)
    var imageData: Data?{
        if let imageData=self.image?.pngData{
            return imageData
        }
        else if let contents=self.contents{
            return contents
        }
        else{
            return self.fileWrapper?.regularFileContents
        }
    }
    
    var dataImageSize:CGSize{
        if let image=self.image{
            return image.size
        }
        else{
            guard let data=self.imageData,
                  let image=UIImage(data: data)
            else {return .zero}
            return image.size
        }
    }
    
    var extentInEMU:Size{
        let size:CGSize
        if self.bounds != .zero{
            size=self.bounds.size
        }
        else{
            size=self.dataImageSize
        }
        
        let width=size.width
        let height=size.height

        let emuPerInch=CGFloat(914400)
        let dpi=CGFloat(72)
        let emuWidth=width/dpi*emuPerInch
        let emuHeight=height/dpi*emuPerInch
        return Size(width: Int(emuWidth), height: Int(emuHeight))
        
    }
    
    var extentAttributes:[AEXMLElement]{
        let size=self.extentInEMU
        let extent=size.extentAttribute
        let effectiveExtent=AEXMLElement(name: "wp:effectExtent", value: nil, attributes: ["l":"0", "t":"0","r":"0","b":"0"])
        return [extent,effectiveExtent]
    }
}
