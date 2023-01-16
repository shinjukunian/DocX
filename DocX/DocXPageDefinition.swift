//
//  DocXPageDefinition.swift
//  
//
//  Created by Morten Bertz on 2023/01/13.
//

import CoreGraphics
import Foundation
import AEXML

#if canImport(UIKit)
import UIKit
fileprivate typealias NSEdgeInsets = UIEdgeInsets
#endif

public struct PageDefinition: Equatable, CustomStringConvertible, Hashable{
        
    /// The size of a page
    public struct PageSize:Equatable, CustomStringConvertible, Hashable{
        
        ///Page width in twips
        let width:Measurement<UnitLength>
        
        /// Page height in twips
        let height:Measurement<UnitLength>
        
        /// Convenience initializer using a `CGSize`. All values are in points.
        public init(size:CGSize){
            self.width = Measurement(value: size.width, unit: UnitLength.points)
            self.height = Measurement(value: size.height, unit: UnitLength.points)
        }
        
        /// Convenience initializer to define the page size in length units (mm, cm, inches)
        /// - Parameters:
        ///     - width: the width if the page as a length measurement
        ///     - height: the width if the page as a length measurement
        /// Discussion:
        ///
        /// For an A4 page (21 cm x 29.7 cm), use
        /// ```
        /// let width=Measurement(value: 21, unit: UnitLength.centimeters)
        /// let height=Measurement(value: 29.7, unit: UnitLength.centimeters)
        /// let page=PageSize(width: width, height: height)
        /// ```
        public init(width:Measurement<UnitLength>, height: Measurement<UnitLength>){
            self.width = width
            self.height = height
        }
        
        public var description: String{
            let formatter=MeasurementFormatter()
            formatter.unitOptions = [.providedUnit]
            return "Width: \(formatter.string(from: width.converted(to: .points))), height: \(formatter.string(from: height.converted(to: .points)))\rWidth: \(formatter.string(from: width.converted(to: UnitLength.centimeters))), height: \(formatter.string(from: height.converted(to: UnitLength.centimeters)))"
        }
        
        /// An A4 page
        public static let A4:PageSize = PageSize(size: .init(width: 595, height: 842))
        
        /// A Letter page
        public static let letter:PageSize = PageSize(size: .init(width: 612, height: 792))
        
        var pageSizeElement:AEXMLElement{
            let width=Int(width.converted(to: .twips).value)
            let height=Int(height.converted(to: .twips).value)
            return AEXMLElement(name: "w:pgSz", value: nil, attributes: ["w:w":String(width), "w:h":String(height), "w:orient":"landscape"])
        }
        
        /// The size of the page in points
        public var cgSize:CGSize{
            return size(unit: .points)
        }
        
        /// The size of the page in in a desired unit of length (cm, mm, inches, etc.)
        public func size(unit:UnitLength)->CGSize{
            return CGSize(width: width.converted(to: unit).value, height: height.converted(to: unit).value)
        }
    }
    
    /// The margins of a page (insets of the printable area).
    public struct PageMargins:Equatable, CustomStringConvertible, Hashable{
        
        /// Top margin in twips
        let top:Measurement<UnitLength>
        
        /// bottom margin in twips.
        let bottom:Measurement<UnitLength>
        
        /// left margin in twips
        let left:Measurement<UnitLength>
        
        /// right margin in twips
        let right:Measurement<UnitLength>
        
        /// footer margin in twips. The larger value of `bottom` or `footer` will be used
        let footer:Measurement<UnitLength>
        
        /// header margin in twips. The larger value of `header` and `top` will be used.
        let header:Measurement<UnitLength>
        
        
        /// Convenience initializer. All values are in points. One inch (2.54 cm) is 72 points.
        /// - Parameters:
        ///     - top: top margin
        ///     - bottom: bottom margin
        ///     - left: left margin
        ///     - right: right margin
        ///     - footer: footer margin
        ///     - header: header margin
        public init(top:CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat, footer: CGFloat = 0, header: CGFloat = 0) {
            self.top = Measurement(value: top, unit: UnitLength.points)
            self.bottom = Measurement(value: bottom, unit: UnitLength.points)
            self.left = Measurement(value: left, unit: UnitLength.points)
            self.right = Measurement(value: right, unit: UnitLength.points)
            self.footer = Measurement(value: footer, unit: UnitLength.points)
            self.header = Measurement(value: header, unit: UnitLength.points)
        }
        
        /// Memberwise initializer to define the margins size in length units (mm, cm, inches)
        /// - Parameters:
        ///     - top: top margin
        ///     - bottom: bottom margin
        ///     - left: left margin
        ///     - right: right margin
        ///     - footer: footer margin
        ///     - header: header margin
        public init(top:Measurement<UnitLength>, bottom: Measurement<UnitLength>, left: Measurement<UnitLength>, right: Measurement<UnitLength>, footer: Measurement<UnitLength> = Measurement(value: 0, unit: .centimeters), header: Measurement<UnitLength> = Measurement(value: 0, unit: .centimeters)){
            self.top = top
            self.bottom = bottom
            self.left = left
            self.right = right
            self.footer = footer
            self.header = header
        }
        
#if os(macOS)
        /// Convenience initializer. Edge insets are in points.
        public init(edgeInsets:NSEdgeInsets){
            self.init(top: edgeInsets.top, bottom: edgeInsets.bottom, left: edgeInsets.left, right: edgeInsets.right)
        }
        
#elseif os(iOS)
        /// Convenience initializer. Edge insets are in points.
        public init(edgeInsets:UIEdgeInsets){
            self.init(top: edgeInsets.top, bottom: edgeInsets.bottom, left: edgeInsets.left, right: edgeInsets.right)
        }
        
#endif
        fileprivate var effectiveMargins:NSEdgeInsets{
            return effectiveMargins(unit: .points)
        }
        
        /// Effective margins of the page in a unit of length.
        public func effectiveMargins(unit:UnitLength)->NSEdgeInsets{
            let top = top < Measurement(value: 0, unit: .points) ? top : max(top, header)
            let bottom = bottom < Measurement(value: 0, unit: .points) ? bottom : max(bottom, footer)
            return NSEdgeInsets(top: top.converted(to: unit).value, left: left.converted(to: unit).value, bottom: bottom.converted(to: unit).value, right: right.converted(to: unit).value)
        }
        
        public var description: String{
            let formatter=MeasurementFormatter()
            formatter.unitOptions = [.providedUnit]
            return "Top \(formatter.string(from: top.converted(to: .points))), bottom: \(formatter.string(from: bottom.converted(to: .points))), left: \(formatter.string(from: left.converted(to: .points))), right: \(formatter.string(from: right.converted(to: .points))), footer: \(formatter.string(from: footer.converted(to: .points))), header: \(formatter.string(from: header.converted(to: .points)))\rTop \(formatter.string(from: top.converted(to: .centimeters))), bottom: \(formatter.string(from: bottom.converted(to: .centimeters))), left: \(formatter.string(from: left.converted(to: .centimeters))), right: \(formatter.string(from: right.converted(to: .centimeters))), footer: \(formatter.string(from: footer.converted(to: .centimeters))), header: \(formatter.string(from: header.converted(to: .centimeters)))"
        }
        
        /// The default margins of a standard Word document (one inch).
        public static let `default` = PageMargins(top: CGFloat(72), bottom: 72, left: 72, right: 72, footer: 35.4, header: 35.4)
        
        var marginElement:AEXMLElement{
            return AEXMLElement(name: "w:pgMar", value: nil, attributes: ["w:top":String(Int(top.converted(to: .twips).value)), "w:right":String(Int(right.converted(to: .twips).value)), "w:bottom":String(Int(bottom.converted(to: .twips).value)), "w:left":String(Int(left.converted(to: .twips).value)), "w:header":String(Int(header.converted(to: .twips).value)), "w:footer":String(Int(footer.converted(to: .twips).value)), "w:gutter":"0"])
        }
    }
    
    /// The page size of the document
    let pageSize:PageSize
    
    /// The page margins of the document
    let pageMargins:PageMargins
    
    public var description: String{
        return "Paper Size: \(pageSize),\r\rMargins: \(pageMargins)"
    }
    
   
    /// Initializes a page Definition with a page (paper) size and margins
    /// - Parameters:
    ///     - pageSize: a page (paper) size, e.g. A4.
    ///     - pageMargins: the margins from the edge of the page to the borders of the printed text.
    public init(pageSize: PageSize, pageMargins: PageMargins = .default) {
        self.pageSize = pageSize
        self.pageMargins = pageMargins
    }
    
   
    /// The effective printable area of the page in a unit of length.
    public func printableSize(unit: UnitLength = .points) ->CGSize{
        let size=self.pageSize.size(unit: unit)
        let margins=self.pageMargins.effectiveMargins(unit: unit)
        return CGSize(width: size.width - margins.right - margins.left, height: size.height - margins.bottom - margins.top)
    }
    
    
    var pageElements:[AEXMLElement]{
        return [pageSize.pageSizeElement, pageMargins.marginElement]
    }
    
}


public extension UnitLength{
    class var points:UnitLength{
        return UnitLength(symbol: "points", converter: UnitConverterLinear(coefficient: 1/100 / 72 * 2.54))
    }
    
    class var twips:UnitLength{
        return UnitLength(symbol: "twips", converter: UnitConverterLinear(coefficient: 1/100 / 72 * 2.54 / 20))
    }
}

