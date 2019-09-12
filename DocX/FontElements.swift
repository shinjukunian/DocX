//
//  FontElements.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/12.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import AEXML

extension NSFont{
    var attributeElements:[AEXMLElement]{
        return [FontElement(font: self), FontSizeElement(font: self),BoldElement(font: self),ItalicElement(font: self)].compactMap({$0})
    }
}

class FontElement:AEXMLElement{
    fileprivate override init(name: String, value: String? = nil, attributes: [String : String] = [String : String]()) {
        super.init(name: name, value: value, attributes: attributes)
    }
    
    init(font:NSFont) {
        #if os(iOS)
        let name=font.familyName
        #elseif os(macOS)
        let name=font.familyName ?? font.fontName
        #endif
        let attributes=["w:ascii":name, "w:eastAsia":name, "w:hAnsi":name, "w:cs":name]
        super.init(name: "w:rFonts", value: nil, attributes: attributes)
    }
}

class BoldElement:AEXMLElement{
    init?(font: NSFont) {
        if font.fontDescriptor.symbolicTraits.contains(boldTrait){
            super.init(name: "w:b")
        }
        else{
            return nil
        }
    }
}

class ItalicElement:AEXMLElement{
    init?(font: NSFont) {
        if font.fontDescriptor.symbolicTraits.contains(italicTrait){
            super.init(name: "w:i")
        }
        else{
            return nil
        }
    }
}

class FontSizeElement:AEXMLElement{
    fileprivate override init(name: String, value: String? = nil, attributes: [String : String] = [String : String]()) {
        fatalError()
    }
    init(font:NSFont) {
        let attributes=["w:val":String(Int(font.pointSize*2))]
        super.init(name: "w:sz", value: nil, attributes: attributes)
        
    }
}
