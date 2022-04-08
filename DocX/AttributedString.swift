//
//  AttributedString.swift
//  
//
//  Created by Morten Bertz on 2021/06/29.
//

import Foundation
import AEXML

@available(macOS 12, iOS 15, *)
extension AttributedString{
    
    public func writeDocX(to url: URL) throws{
        
        #if os(macOS)
        let scope=AttributeScopes.AppKitAttributes.self
        #elseif os(iOS)
        let scope=AttributeScopes.UIKitAttributes.self
        #else
        let scope=AttributeScopes.FoundationAttributes.self
        #endif
        
        let nsAtt=try NSAttributedString(self, including: scope)
        try nsAtt.writeDocX(to: url)
    }
}


@available(macOS 12,iOS 15, *)
extension AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute{
    static let key:NSAttributedString.Key = NSAttributedString.Key(rawValue: AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute.name)
}

@available(macOS 12, iOS 15, *)
extension AttributeScopes.FoundationAttributes.ImageURLAttribute{
    static let key:NSAttributedString.Key = NSAttributedString.Key(rawValue: AttributeScopes.FoundationAttributes.ImageURLAttribute.name)
}


@available(macOS 12, iOS 15, *)
extension InlinePresentationIntent{
    var element:AEXMLElement?{
        switch self{
        case .stronglyEmphasized:
            return AEXMLElement(name: "w:b", value: nil, attributes: ["w:val":"true"])
        case .strikethrough:
            return AEXMLElement(name: "w:strike", value: nil, attributes: ["w:val":"true"])
        case .emphasized:
            return AEXMLElement(name: "w:i", value: nil, attributes: ["w:val":"true"])
        default:
            return nil
        }
    }
}
