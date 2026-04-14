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
    
    /// The image data
    let attachement:NSTextAttachment
    
    /// The size of the page
    let pageDefinition:PageDefinition?
    
    /// The image width as a fraction of the printable column width
    /// When `nil`, the image uses its native dimensions (constrained to the page)
    var imageWidthFraction: Double?
    
    /// How text flows around the image. When `nil`, the image is rendered inline
    /// Set to `.left` or `.right` to produce a floating image with square text wrapping
    var imageFlow: DocXImageAttachment.Flow?
    
    /// Alt text for the image
    var imageDescription: String?
}

extension ImageRelationship{
    
    /// Constructs the meta attributes for an image
    private var imageMetaAttributes: [String: String] {
        let id = relationshipID.trimmingCharacters(in: .letters)
        var meta = ["id": id, "name": "image"]

        // Include the image description (alt text), if specified
        if let imageDescription,
           !imageDescription.isEmpty {
            meta["descr"] = imageDescription
        }

        return meta
    }
    
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
        // If flow is specified, we'll return an anchored image with square text wrapping
        if let imageFlow {
            return anchoredAttributeElement(flow: imageFlow)
        }
        
        // We can return an inline image (no text wrapping)
        return inlineAttributeElement
    }
    
    /// Returns XML for an inline image (no text wrapping)
    private var inlineAttributeElement: AEXMLElement {
        let run=AEXMLElement(name: "w:r", value: nil, attributes: [:])
        let para=AEXMLElement(name: "w:rPr")
        para.addChild(AEXMLElement(name: "w:noProof"))
        run.addChild(para)
        
        let drawing=AEXMLElement(name: "w:drawing", value: nil, attributes: ["xmlns:a":"http://schemas.openxmlformats.org/drawingml/2006/main"])
        run.addChild(drawing)
        
        let inline=AEXMLElement(name: "wp:inline", value: nil, attributes: ["distT":String(0), "distB":String(0), "distL":String(0), "distR":String(0)])
        drawing.addChild(inline)

        let size = attachement.sizeInEMU(imageWidthFraction: imageWidthFraction, pageSize: pageDefinition)
        let extent = size.extentAttribute
        let effectiveExtent=AEXMLElement(name: "wp:effectExtent", value: nil, attributes: ["l":"0", "t":"0","r":"0","b":"0"])
        let meta = imageMetaAttributes
        let docPr=AEXMLElement(name: "wp:docPr", value: nil, attributes: meta)
        let frameProperties=AEXMLElement(name: "wp:cNvGraphicFramePr")
        frameProperties.addChild(AEXMLElement(name: "a:graphicFrameLocks", value: nil, attributes: ["xmlns:a":"http://schemas.openxmlformats.org/drawingml/2006/main", "noChangeAspect":"1"]))

        let graphic=AEXMLElement(name: "a:graphic", value: nil, attributes: ["xmlns:a":"http://schemas.openxmlformats.org/drawingml/2006/main"])
        
        inline.addChildren([extent, effectiveExtent, docPr, frameProperties, graphic])
        
        let graphicData=AEXMLElement(name: "a:graphicData", value: nil, attributes: ["uri":"http://schemas.openxmlformats.org/drawingml/2006/picture"])
        
        graphic.addChild(graphicData)
        graphicData.addChild(picElement(size: size, meta: meta))
        
        return run
    }

    /// Returns XML for an anchored image with the specified `flow`
    private func anchoredAttributeElement(flow: DocXImageAttachment.Flow) -> AEXMLElement {
        let run = AEXMLElement(name: "w:r", value: nil, attributes: [:])
        let para = AEXMLElement(name: "w:rPr")
        para.addChild(AEXMLElement(name: "w:noProof"))
        run.addChild(para)

        let drawing = AEXMLElement(name: "w:drawing", value: nil, attributes: ["xmlns:a":"http://schemas.openxmlformats.org/drawingml/2006/main"])
        run.addChild(drawing)

        let textSideMargin = "91440"
        let distL: String
        let distR: String
        switch flow {
        case .left:
            distL = "0"
            distR = textSideMargin
        case .right:
            distL = textSideMargin
            distR = "0"
        }

        let anchor = AEXMLElement(name: "wp:anchor", value: nil, attributes: [
            "distT": "0",
            "distB": "0",
            "distL": distL,
            "distR": distR,
            "simplePos": "0",
            "relativeHeight": "0",
            "behindDoc": "0",
            "locked": "0",
            "layoutInCell": "1",
            "allowOverlap": "1"
        ])
        drawing.addChild(anchor)

        anchor.addChild(AEXMLElement(name: "wp:simplePos", value: nil, attributes: ["x": "0", "y": "0"]))

        let positionH = AEXMLElement(name: "wp:positionH", value: nil, attributes: ["relativeFrom": "column"])
        positionH.addChild(AEXMLElement(name: "wp:align", value: flow == .left ? "left" : "right"))
        anchor.addChild(positionH)

        let positionV = AEXMLElement(name: "wp:positionV", value: nil, attributes: ["relativeFrom": "paragraph"])
        positionV.addChild(AEXMLElement(name: "wp:posOffset", value: "0"))
        anchor.addChild(positionV)

        let size = attachement.sizeInEMU(imageWidthFraction: imageWidthFraction, pageSize: pageDefinition)
        anchor.addChild(size.extentAttribute)
        anchor.addChild(AEXMLElement(name: "wp:effectExtent", value: nil, attributes: ["l":"0", "t":"0", "r":"0", "b":"0"]))
        anchor.addChild(AEXMLElement(name: "wp:wrapSquare", value: nil, attributes: ["wrapText": "bothSides"]))

        let meta = imageMetaAttributes
        anchor.addChild(AEXMLElement(name: "wp:docPr", value: nil, attributes: meta))

        let frameProperties = AEXMLElement(name: "wp:cNvGraphicFramePr")
        frameProperties.addChild(AEXMLElement(name: "a:graphicFrameLocks", value: nil, attributes: ["xmlns:a":"http://schemas.openxmlformats.org/drawingml/2006/main", "noChangeAspect":"1"]))
        anchor.addChild(frameProperties)

        let graphic = AEXMLElement(name: "a:graphic", value: nil, attributes: ["xmlns:a":"http://schemas.openxmlformats.org/drawingml/2006/main"])
        anchor.addChild(graphic)

        let graphicData = AEXMLElement(name: "a:graphicData", value: nil, attributes: ["uri":"http://schemas.openxmlformats.org/drawingml/2006/picture"])
        graphic.addChild(graphicData)
        graphicData.addChild(picElement(size: size, meta: meta))

        return run
    }

    private func picElement(size: NSTextAttachment.Size, meta: [String:String]) -> AEXMLElement {
        let pic=AEXMLElement(name: "pic:pic", value: nil, attributes: ["xmlns:pic":"http://schemas.openxmlformats.org/drawingml/2006/picture"])
        
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
        let extent=AEXMLElement(name: "a:ext", value: nil, attributes: size.extentAttributes)
        xFrame.addChild(extent)
        shapeProperties.addChild(xFrame)
        
        let geometry=AEXMLElement(name: "a:prstGeom", value: nil, attributes: ["prst":"rect"])
        geometry.addChild(AEXMLElement(name: "a:avLst"))
        shapeProperties.addChild(geometry)
        
        return pic
    }
    
}
