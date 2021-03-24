//
//  File.swift
//  
//
//  Created by Morten Bertz on 2021/03/23.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

import AEXML

struct ImageRelationship: DocumentRelationship{
    let relationshipID:String
    let linkURL:URL
    let attachement:NSTextAttachment
}

extension ImageRelationship{
    
    var linkString:String {
        return self.linkURL.pathComponents.suffix(2).joined(separator: "/")
    }
    
    var element:AEXMLElement{
        return AEXMLElement(name: "Relationship", value: nil, attributes: ["Id":self.relationshipID, "Type":"http://schemas.openxmlformats.org/officeDocument/2006/relationships/image", "Target":linkString])
    }
    
    
    /*
     <w:drawing>
     <wp:inline distT="0" distB="0" distL="0" distR="0">
     <wp:extent cx="2438400" cy="1828800"/>
     <wp:effectExtent l="19050" t="0" r="0" b="0"/>
     <wp:docPr id="1" name="Picture 0" descr="Blue hills.jpg"/>
     <wp:cNvGraphicFramePr>
     <a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/>
     </wp:cNvGraphicFramePr>
     <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
     <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
     <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
     . . .
     </pic:pic>
     </a:graphicData>
     </a:graphic>
     </wp:inline>
     </w:drawing>
     */
    
    
    /*
     <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
     <pic:nvPicPr>
     <pic:cNvPr id="0" name="Blue hills.jpg"/>
     <pic:cNvPicPr/>
     </pic:nvPicPr>
     <pic:blipFill>
     <a:blip r:embed="rId4" cstate="print"/>
     <a:stretch>
     <a:fillRect/>
     </a:stretch/>
     </pic:blipFill>
     <pic:spPr>
     <a:xfrm>
     <a:off x="0" y="0"/>
     <a:ext cx="2438400" cy="1828800"/>
     </a:xfrm>
     <a:prstGeom rst="rect>
     <a:avLst/>
     </a:prstGeom>
     </pic:spPr>
     </pic:pic>
     */
    
    var attributeElement:AEXMLElement{
        
        let run=AEXMLElement(name: "w:r", value: nil, attributes: [:])
        let para=AEXMLElement(name: "w:rPr")
        para.addChild(AEXMLElement(name: "w:noProof"))
        run.addChild(para)
        
        let drawing=AEXMLElement(name: "w:drawing", value: nil, attributes: ["xmlns:a":"http://schemas.openxmlformats.org/drawingml/2006/main"])
        run.addChild(drawing)
        
        let inline=AEXMLElement(name: "wp:inline", value: nil, attributes: ["distT":String(0), "distB":String(0), "distL":String(0), "distR":String(0)])
        drawing.addChild(inline)
        
        let graphic=AEXMLElement(name: "a:graphic", value: nil, attributes: ["xmlns:a":"http://schemas.openxmlformats.org/drawingml/2006/main"])
        let id=self.relationshipID.trimmingCharacters(in: .letters)
        let meta=["id":id, "name":"image", "descr":"An Image"]
        let docPr=AEXMLElement(name: "wp:docPr", value: nil, attributes: meta)
        let frameProperties=AEXMLElement(name: "wp:cNvGraphicFramePr")
        frameProperties.addChild(AEXMLElement(name: "a:graphicFrameLocks", value: nil, attributes: ["xmlns:a":"http://schemas.openxmlformats.org/drawingml/2006/main", "noChangeAspect":"1"]))
        
        inline.addChildren(attachement.extentAttributes + [docPr, frameProperties, graphic])
        
        let graphicData=AEXMLElement(name: "a:graphicData", value: nil, attributes: ["uri":"http://schemas.openxmlformats.org/drawingml/2006/picture"])
        
        graphic.addChild(graphicData)
        
        let pic=AEXMLElement(name: "pic:pic", value: nil, attributes: ["xmlns:pic":"http://schemas.openxmlformats.org/drawingml/2006/picture"])
        graphicData.addChild(pic)
        
        let nvPicPr=AEXMLElement(name: "pic:nvPicPr")
        nvPicPr.addChild(AEXMLElement(name: "pic:cNvPr", value: nil, attributes: meta))
        let picNonVisual=AEXMLElement(name: "pic:cNvPicPr")
        picNonVisual.addChild(AEXMLElement(name: "a:picLocks", value: nil, attributes: ["noChangeAspect":"1"]))
        nvPicPr.addChild(picNonVisual)
        
        pic.addChild(nvPicPr)
        let blipFill=AEXMLElement(name: "pic:blipFill")
        pic.addChild(blipFill)
        let blip=AEXMLElement(name: "a:blip", value: nil, attributes: ["r:embed":self.relationshipID])
        blip.addChild(AEXMLElement(name: "a:extLst"))
        blipFill.addChild(blip)
        let stretch=AEXMLElement(name: "a:stretch")
        stretch.addChild(AEXMLElement(name: "a:fillRect"))
        blipFill.addChild(stretch)
        
        let shapeProperties=AEXMLElement(name: "pic:spPr")
        pic.addChild(shapeProperties)
        let xFrame=AEXMLElement(name: "a:xfrm")
        xFrame.addChild(AEXMLElement(name: "a:off", value: nil, attributes: ["x":"0","y":"0"]))
        let extent=AEXMLElement(name: "a:ext", value: nil, attributes: self.attachement.extentInEMU.extentAttributes)
        xFrame.addChild(extent)
        shapeProperties.addChild(xFrame)
        
        let geometry=AEXMLElement(name: "a:prstGeom", value: nil, attributes: ["prst":"rect"])
        geometry.addChild(AEXMLElement(name: "a:avLst"))
        shapeProperties.addChild(geometry)
        
        return run
    }
    
}

