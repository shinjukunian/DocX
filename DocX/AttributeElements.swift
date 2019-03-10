//
//  FontElement.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import AEXML


extension NSFont{
    var attributeElements:[AEXMLElement]{
        return [FontElement(font: self), FontSizeElement(font: self)].compactMap({$0})
    }
}


class FontElement:AEXMLElement{
    fileprivate override init(name: String, value: String? = nil, attributes: [String : String] = [String : String]()) {
        fatalError()
    }
    
    init?(font:NSFont) {
        if let name=font.familyName{
            let attributes=["w:ascii":name, "w:eastAsia":name, "w:hAnsi":name, "w:cs":name]
            super.init(name: "w:rFonts", value: nil, attributes: attributes)
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

extension NSColor{
    var hexColorString:String{
        return String.init(format: "%02X%02X%02X", Int(self.redComponent*255), Int(self.greenComponent*255), Int(self.blueComponent*255))
    }
    var colorElement:AEXMLElement{
        return AEXMLElement(name: "w:color", value: nil, attributes: ["w:val":self.hexColorString])
    }
}
