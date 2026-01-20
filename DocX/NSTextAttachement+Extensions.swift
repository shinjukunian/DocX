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
        
        init(cgSize:CGSize) {
            self.height=Int(cgSize.height)
            self.width=Int(cgSize.width)
        }
        
        
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
    
    /// Autosizing behavior of images.
    ///
    /// The default behaviour is:
    /// - if an explicit `bounds` has been supplied for the `NSTextAttachement`, use this size (in points)
    /// - if no `bounds` has been suplied (`bounds == CGRect.zero`), use the size of the supplied image (in points).
    /// - if an optional `PageDefinition` is supplied and no explicit size for the `NSTextAttachement` has been set, scale the image to fit the page if it is larger than the printable area, otherwise do nothing.
    func extent(for pageSize:PageDefinition?) -> CGSize{
        let size:CGSize
        if self.bounds != .zero{
            size=self.bounds.size
        }
        else{
            size=self.dataImageSize
        }
        
        let width:CGFloat
        let height:CGFloat
        
        
        // we have a page size defined and the image is larger (in one dimension) than the page. we shrink the image to fit the printable area of the page.
        // If there is a user-defined size, we accept this even if it is too large.
        if let bounds=pageSize?.printableSize(unit: .points),
            size == .zero,
            (bounds.height < size.height || bounds.width < size.width) {
            let ratio=min(bounds.height / size.height, bounds.width / size.width)
            let scaledSize=size.applying(.init(scaleX: ratio, y: ratio))
            width=scaledSize.width
            height=scaledSize.height
        }
        else{
            width=size.width
            height=size.height
        }
        
        return CGSize(width: width, height: height)
    }
    
    
    func extentInEMU(size:CGSize) -> Size{
        let emuPerInch=CGFloat(914400)
        let dpi=CGFloat(72)
        let emuSize=size.applying(.init(scaleX: emuPerInch / dpi, y: emuPerInch / dpi))
        return Size(cgSize: emuSize)
    }
    
    
    func extentAttributes(pageSize:PageDefinition?) -> [AEXMLElement]{
        let size=extentInEMU(size: extent(for: pageSize))
        let extent=size.extentAttribute
        let effectiveExtent=AEXMLElement(name: "wp:effectExtent", value: nil, attributes: ["l":"0", "t":"0","r":"0","b":"0"])
        return [extent,effectiveExtent]
    }
}
