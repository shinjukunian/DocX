//
//  RubyAnnotationElement.swift
//  DocX
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import AEXML

extension CTRubyAnnotation{
    // for documentation, see https://blogs.msdn.microsoft.com/murrays/2014/12/27/ruby-text-objects/
    func rubyElement(baseString:NSAttributedString)->AEXMLElement?{
        guard let rubyText=self.rubyText else{return nil}
        
        let scaleFactor=CTRubyAnnotationGetSizeFactor(self)
        let baseAttributes=baseString.attributes(at: 0, effectiveRange: nil)
        
        let rubyElement=AEXMLElement(name: "w:ruby", value: nil, attributes: [:])
        let rubyFormat=self.rubyFormat(font: baseAttributes[.font] as? NSFont)
        rubyElement.addChild(rubyFormat)
        
        
        
        let rubyTextElementWrapper=AEXMLElement(name: "w:rt", value: nil, attributes: [:])
        rubyElement.addChild(rubyTextElementWrapper)
        let rubyTextElement=AEXMLElement(name: "w:r", value: nil, attributes: ["w:rsidR":"00604B72", "w:rsidRPr":"00604B72"])
        rubyTextElementWrapper.addChild(rubyTextElement)
        
        let rubyRunElement=baseAttributes.rubyAnnotationRunProperties(scaleFactor: scaleFactor)
        rubyTextElement.addChild(rubyRunElement)
       
        let rubyTextLiteral=rubyText.element
        rubyTextElement.addChild(rubyTextLiteral)
        
        let baseElement=AEXMLElement(name: "w:rubyBase", value: nil, attributes: [:])
        rubyElement.addChild(baseElement)
        let baseRun=AEXMLElement(name: "w:r", value: nil, attributes: ["w:rsidR":"00604B72"])
        baseElement.addChild(baseRun)

        let baseRunFormat=baseAttributes.runProperties
        baseRun.addChild(baseRunFormat)
        
        let baseLiteral=baseString.string.element
        baseRun.addChild(baseLiteral)
        
        return rubyElement
    }
    
    var rubyText:String?{
        let positions:[CTRubyPosition]=[.before,.after,.inline,.interCharacter]
        let text=positions.map({CTRubyAnnotationGetTextForPosition(self, $0)}).compactMap({$0}).first
        return text as String?
        
    }
    
    //this is lacking the w:hpsRaise attribute that determines the distance of the annotation from the base text. CoreText doesnt support this, and word falls back to 0 offset if it isnt defined
    func rubyFormat(font:NSFont?)->AEXMLElement{
        let rubyFormat=AEXMLElement(name: "w:rubyPr")
        let scaleFactor=CTRubyAnnotationGetSizeFactor(self)
        if let font=font{
            let size=Int(font.pointSize*scaleFactor*2)
            let rubySizeElement=AEXMLElement(name: "w:hps", value: nil, attributes: ["w:val":String(size)])
            let baseSizeElement=AEXMLElement(name: "w:hpsBaseText", value: nil, attributes: ["w:val":String(Int(font.pointSize*2))])
            let lid=AEXMLElement(name: "w:lid", value: nil, attributes: ["w:val":"ja-JP"])
            let alignment=CTRubyAnnotationGetAlignment(self).alignmentElement
            rubyFormat.addChildren([rubySizeElement,baseSizeElement,lid,alignment])
        }
        return rubyFormat
    }
}

extension CTRubyAlignment{
    
    var alignmentElement:AEXMLElement{
        switch self {
        case .auto, .distributeSpace:
            return AEXMLElement(name: "w:rubyAlign", value: nil, attributes: ["w:val":"distributeSpace"])
        case .center:
            return AEXMLElement(name: "w:rubyAlign", value: nil, attributes: ["w:val":"center"])
        case .distributeLetter:
            return AEXMLElement(name: "w:rubyAlign", value: nil, attributes: ["w:val":"distributeLetter"])
        case .start:
            return AEXMLElement(name: "w:rubyAlign", value: nil, attributes: ["w:val":"left"])
        case .end:
            return AEXMLElement(name: "w:rubyAlign", value: nil, attributes: ["w:val":"right"])
        default:
            return AEXMLElement(name: "w:rubyAlign", value: nil, attributes: ["w:val":"distributeSpace"])
        }
    }
}
