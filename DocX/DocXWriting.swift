//
//  DocXWriting.swift
//  DocXWriter
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Foundation
import AEXML

#if canImport(UIKit)
import UIKit
import MobileCoreServices
fileprivate typealias NSImage = UIImage
#elseif canImport(AppKit)
import AppKit
#endif

enum DocXWriteImageError: Error {
    case noImageData
    case invalidImageData
}

@available(OSX 10.11, *)
extension DocX where Self : NSAttributedString{
    
    func pageDef(options: DocXOptions?) -> AEXMLElement{
        let pageDef=AEXMLElement(name: "w:sectPr", value: nil, attributes: ["w:rsidR":"00045791", "w:rsidSect":"004F37A0"])
        
        if self.usesVerticalForms{
            let vertical=AEXMLElement(name: "w:textDirection", value: nil, attributes: ["w:val":"tbRl"])
            pageDef.addChild(vertical)
        }
        
        if let page=options?.pageDefinition{
            pageDef.addChildren(page.pageElements)
        }
        
        //these elements are added for by word, but not by the cocoa docx exporter. word then falls back to the page setup defined by the print settings of the machine. this seems useful
        
//        let size=AEXMLElement(name: "w:pgSz", value: nil, attributes: ["w:w":"11901", "w:h":"16817", "w:code":"9"])
//        let margins=AEXMLElement(name: "w:pgMar", value: nil, attributes: ["w:top":"0", "w:right":"403", "w:bottom":"0", "w:left":"442", "w:header":"0", "w:footer":"113", "w:gutter":"0"])
//        let cols=AEXMLElement(name: "w:cols", value: nil, attributes: ["w:space":"708"])
//        let grid=AEXMLElement(name: "w:docGrid", value: nil, attributes: ["w:type":"lines", "w:linePitch":"360"])
//        
//        pageDef.addChild(size)
//        pageDef.addChild(margins)
//        pageDef.addChild(cols)
//        pageDef.addChild(grid)
        
        return pageDef
    }
    
    
    func buildParagraphs(paragraphRanges:[ParagraphRange],
                         linkRelations:[DocumentRelationship],
                         options:DocXOptions) -> [AEXMLElement]{
        return paragraphRanges.map({range in
            let paragraph=ParagraphElement(string: self,
                                           range: range,
                                           linkRelations: linkRelations,
                                           options: options)
            return paragraph
        })
    }
    
    func docXDocument(linkRelations:[DocumentRelationship] = [DocumentRelationship](),
                      options:DocXOptions = DocXOptions())throws ->String{
        var xmlOptions=AEXMLOptions()
        xmlOptions.documentHeader.standalone="yes"
        
        // Enable escaping so that reserved characters, like < & >, don't
        // result in an invalid docx file
        // See: https://github.com/shinjukunian/DocX/issues/18
        xmlOptions.escape = true
        
        xmlOptions.lineSeparator="\n"
        let root=DocumentRoot()
        let document=AEXMLDocument(root: root, options: xmlOptions)
        let body=AEXMLElement(name: "w:body")
        root.addChild(body)
        body.addChildren(self.buildParagraphs(paragraphRanges: self.paragraphRanges,
                                              linkRelations: linkRelations,
                                              options: options))
        body.addChild(pageDef(options: options))
        return document.xmlCompact
    }
    
    func lastRelationshipIdIndex(linkXML: AEXMLDocument) -> Int {
        let relationships=linkXML["Relationships"]
        let presentIds=relationships.children.map({$0.attributes}).compactMap({$0["Id"]}).sorted(by: {s1, s2 in
            return s1.compare(s2, options: [.numeric], range: nil, locale: nil) == .orderedAscending
        })
        
        let lastIdIDX:Int
        if let lastID=presentIds.last?.trimmingCharacters(in: .letters){
            lastIdIDX=Int(lastID) ?? 0
        }
        else{
            lastIdIDX=0
        }
        
        return lastIdIDX
    }
   
    func prepareLinks(linkXML: AEXMLDocument, mediaURL:URL) -> [DocumentRelationship] {
        var linkURLS=[URL]()
        
        let imageRelationships = prepareImages(linkXML: linkXML, mediaURL:mediaURL)
        
        self.enumerateAttribute(.link, in: NSRange(location: 0, length: self.length), options: [.longestEffectiveRangeNotRequired], using: {attribute, _, stop in
            if let link=attribute as? URL{
                linkURLS.append(link)
            }
        })
        guard linkURLS.count > 0 else {return imageRelationships}
        
        let lastIdIDX = lastRelationshipIdIndex(linkXML: linkXML)
        
        let linkRelationShips=linkURLS.enumerated().map({(arg)->LinkRelationship in
            let (idx, url) = arg
            let newID="rId\(lastIdIDX+1+idx)"
            let relationShip=LinkRelationship(relationshipID: newID, linkURL: url)
            return relationShip
        })
        
        let relationships=linkXML["Relationships"]
        relationships.addChildren(linkRelationShips.map({$0.element}))
        
        return linkRelationShips + imageRelationships
    }
    
    func prepareImages(linkXML: AEXMLDocument, mediaURL:URL) -> [DocumentRelationship]{
        var attachements=[NSTextAttachment]()
        self.enumerateAttribute(.attachment, in: NSRange(location: 0, length: self.length), options: [.longestEffectiveRangeNotRequired], using: {attribute, _, stop in
            if let link=attribute as? NSTextAttachment{
                attachements.append(link)
            }
        })
        
        if #available(macOS 12.0, iOS 15.0, *) {
            self.enumerateAttribute(.imageURL, in: NSRange(location: 0, length: self.length), options: [.longestEffectiveRangeNotRequired], using: {attribute, _, stop in
                if let link=attribute as? URL,
                   let wrapper=try? FileWrapper(url: link){
                    let attachement=NSTextAttachment(fileWrapper: wrapper)
                    attachements.append(attachement)
                }
            })
        }
            
        guard attachements.count > 0 else {return [ImageRelationship]()}
        
        let relationships=linkXML["Relationships"]
        let presentIds=relationships.children.map({$0.attributes}).compactMap({$0["Id"]}).sorted(by: {s1, s2 in
            return s1.compare(s2, options: [.numeric], range: nil, locale: nil) == .orderedAscending
        })
        
        let lastIdIDX:Int
        
        if let lastID=presentIds.last?.trimmingCharacters(in: .letters){
            lastIdIDX=Int(lastID) ?? 0
        }
        else{
            lastIdIDX=0
        }
        
        if ((try? mediaURL.checkResourceIsReachable()) ?? false) == false{
            try? FileManager.default.createDirectory(at: mediaURL, withIntermediateDirectories: false, attributes: [:])
        }
        
        let imageRelationShips=attachements.enumerated().compactMap({(idx, attachement)->ImageRelationship? in
            // Construct the new relationship identifier
            let newID="rId\(lastIdIDX+1+idx)"

            // Attempt to write the image
            if let destURL = try? writeImage(attachment: attachement,
                                                mediaURL: mediaURL,
                                                newID: newID) {
                // We successfully wrote the image
                // Return the image relationship
                return ImageRelationship(relationshipID: newID,
                                         linkURL: destURL,
                                         attachement: attachement)
            } else {
                // Something went wrong
                return nil
            }
        })
        
        relationships.addChildren(imageRelationShips.map({$0.element}))
        
        return imageRelationShips
    }
    
    private func writeImage(attachment: NSTextAttachment, mediaURL: URL, newID: String) throws -> URL {
        // If there's no image data, return
        guard var imageData = attachment.imageData else {
            throw DocXWriteImageError.noImageData
        }
        
        // See if the text attachment's `fileType` is known
        // If it is, we'll find a valid file extension
        let fileExtension: String?
        if let fileType = attachment.fileType,
           let ext = imageFileExtension(fileType: fileType) {
            // The `fileType` is known so we'll use the returned file extension
            fileExtension = ext
        } else if let image = NSImage(data: imageData),
                  let pngData = image.pngData {
            // The `fileType` isn't known, but we were able to convert
            // the image data to PNG data. Use that instead.
            imageData = pngData
            fileExtension = "png"
        } else {
            fileExtension = nil
        }
        
        // If the image data is invalid – e.g. we don't have a valid extension –
        // there's nothing to do
        guard let fileExtension = fileExtension else {
            throw DocXWriteImageError.invalidImageData
        }

        // Construct the path we'll write to
        let destURL = mediaURL.appendingPathComponent(newID).appendingPathExtension(fileExtension)
        
        // Attempt to write the image
        try imageData.write(to: destURL, options: .atomic)
        
        // Return the URL of the image
        return destURL
    }
    
    /// Returns the file extension for a known `fileType`
    ///
    /// ** When adding a new supported fileType to this function,
    ///    remember to add a corresponding entry for the extension
    ///    and mimetype to [Content_Types].xml**
    private func imageFileExtension(fileType:String) -> String? {
        if (fileType == String(kUTTypeGIF)) {
            return "gif"
        } else if (fileType == String(kUTTypeJPEG)) {
            return "jpeg"
        } else if (fileType == String(kUTTypePNG)) {
            return "png"
        } else if (fileType == String(kUTTypeTIFF)) {
            return "tiff"
        } else if (fileType == String(kUTTypePDF)) {
            return "pdf"
        } else if (fileType == "com.adobe.photoshop-image") {
            return "psd"
        } else {
            return nil
        }
    }
}

extension LinkRelationship{
    
    //<Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink" Target="https://www.rakuten-sec.co.jp/ITS/V_ACT_Login.html" TargetMode="External"/>
    var element:AEXMLElement{
        return AEXMLElement(name: "Relationship", value: nil, attributes: ["Id":self.relationshipID, "Type":"http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink", "Target":self.linkURL.absoluteString, "TargetMode":"External"])
    }
    
}

