//
//  ImageGeneration.swift
//  
//
//  Created by Morten Bertz on 2023/03/05.
//

import Foundation
import CoreGraphics

#if(canImport(UniformTypeIdentifiers))
import UniformTypeIdentifiers
#endif

import ImageIO

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
fileprivate typealias UIFont = NSFont
fileprivate typealias UIColor = NSColor
#endif

@available(iOS 16.0, macOS 11.0, *)
class ImageGenerator{
    
    enum ImageGenerationError: Error{
        case unsupportedFileType
        case imageWritingError
    }
    
    let size:CGSize
    
    init(size:CGSize){
        self.size=size
    }
    
    func generateImage(type:UTType) throws -> URL{
        let outURL=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(for: type)
        switch type{
        case .pdf:
            var rect=CGRect(origin: .zero, size: size)
            guard let ctx=CGContext(outURL as CFURL, mediaBox: &rect, nil) else{
                throw ImageGenerationError.imageWritingError
            }
            ctx.beginPDFPage(nil)
            draw(in: ctx, type: type)
            ctx.endPDFPage()
            ctx.closePDF()
            return outURL
            
        case .png, .jpeg, .tiff:
            let info=CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
            guard let ctx=CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info.rawValue)
            else{
                throw ImageGenerationError.imageWritingError
            }
            let rect=CGRect(origin: .zero, size: size)
            ctx.clear(rect)
            draw(in: ctx, type: type)
            guard let image=ctx.makeImage(),
                  let dest=CGImageDestinationCreateWithURL(outURL as CFURL, type.identifier as CFString, 1, nil)
            else{
                throw ImageGenerationError.imageWritingError
            }
            CGImageDestinationAddImage(dest, image, nil)
            let retVal=CGImageDestinationFinalize(dest)
            guard retVal == true else{
                throw ImageGenerationError.imageWritingError
            }
            
            return outURL
        default:
            throw ImageGenerationError.unsupportedFileType
        }
    }
    
    
    private func draw(in ctx:CGContext, type:UTType){
        let rect=CGRect(origin: .zero, size: size)
    
        ctx.setFillColor(red: 1, green: 0, blue: 0, alpha: 0.9)
        ctx.fillEllipse(in: rect)
        ctx.textMatrix = .identity
        
        let text=NSAttributedString(string: "DocX \(type.localizedDescription ?? "")", attributes: [.font: UIFont(name: "Helvetica", size: size.height / 10.0) as Any,.foregroundColor: UIColor.black])
        let textRect=text.boundingRect(with: size, context: nil)
        let origin=CGPoint(x: (rect.width - textRect.width)/2, y: (rect.height - textRect.height)/2)
        let line=CTLineCreateWithAttributedString(text)
        ctx.saveGState()
        ctx.translateBy(x: origin.x, y: origin.y)
        CTLineDraw(line, ctx)
        ctx.restoreGState()
    }
}
