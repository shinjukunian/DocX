//
//  UIColor+Components.swift
//  DocX-iOS
//
//  Created by Morten Bertz on 2019/03/11.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation

#if os(iOS)
import UIKit

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
    
    var hexColorString:String{
        if let cgRGB=self.cgColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil){
            let rgbColor=UIColor(cgColor: cgRGB)
            return String.init(format: "%02X%02X%02X", Int(rgbColor.redComponent*255), Int(rgbColor.greenComponent*255), Int(rgbColor.blueComponent*255))
        }
        else{
            return "FFFFFF"
        }
        
    }
}


@objc public class DocXActivityItemProvider:UIActivityItemProvider{
    
    let attributedString:NSAttributedString
    let tempURL:URL
    
    @objc public init(attributedString:NSAttributedString) {
        self.attributedString=attributedString
        let tempURL:URL
        if #available(iOS 10.0, *) {
            tempURL=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("docx")
        } else {
            tempURL=URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString).appendingPathExtension("docx")
        }
        self.tempURL=tempURL
        super.init(placeholderItem: tempURL)
    }
    
    public override func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return docXUTIType
    }
    
    public override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return self.tempURL
    }
    
    public override var item: Any{
        do{
            try self.attributedString.writeDocX(to: self.tempURL)
            return self.tempURL
        }
        catch let error{
            print(error)
            return error
        }
    }
}

@available(iOSApplicationExtension 12.0, *)
public extension NSAttributedString{
    
    @available(iOS 13.0, *)
    @objc func attributedString(for userInterfaceStyle:UIUserInterfaceStyle)->NSAttributedString{
        let traitCollection=UITraitCollection(userInterfaceStyle: userInterfaceStyle)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: UITraitCollection.current){
            let mutableSelf=NSMutableAttributedString(attributedString: self)
            
            traitCollection.performAsCurrent {
                mutableSelf.enumerateAttributes(in: NSRange(location: 0, length: mutableSelf.length), options: [], using: {attribute, range, _ in
                    if let foregroundColor=attribute[.foregroundColor] as? UIColor{
                        let fixedColor=UIColor(cgColor: foregroundColor.cgColor)
                        mutableSelf.addAttribute(.foregroundColor, value: fixedColor, range: range)
                    }
                    else if let backgroundColor=attribute[.backgroundColor] as? UIColor{
                        let fixedColor=UIColor(cgColor: backgroundColor.cgColor)
                        mutableSelf.addAttribute(.backgroundColor, value: fixedColor, range: range)
                    }
                })
            }
            
            return mutableSelf
        }
        else{
            return self
        }
    }
    
}

#endif
