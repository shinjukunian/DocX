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
        let width:Int
        
        /// Page height in twips
        let height:Int
        
        /// Memberwise initializer, width and height are in twips (point / 20)
        init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }
        
        /// Convenience initializer using a `CGSize`. All values are in points.
        public init(size:CGSize){
            self.width = Int(Measurement(value: size.width, unit: UnitLength.points).converted(to: .twips).value)
            self.height = Int(Measurement(value: size.height, unit: UnitLength.points).converted(to: .twips).value)
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
            self.width = Int(width.converted(to: .twips).value)
            self.height = Int(height.converted(to: .twips).value)
        }
        
        public var description: String{
            let formatter=MeasurementFormatter()
            formatter.unitOptions = [.providedUnit]
            return "Width: \(formatter.string(from: Measurement(value: Double(width), unit: UnitLength.twips).converted(to: .points))), height: \(formatter.string(from: Measurement(value: Double(height), unit: UnitLength.twips).converted(to: .points)))\rWidth: \(formatter.string(from: Measurement(value: Double(width), unit: UnitLength.twips).converted(to: UnitLength.centimeters))), height: \(formatter.string(from: Measurement(value: Double(height), unit: UnitLength.twips).converted(to: UnitLength.centimeters)))"
        }
        
        /// An A4 page
        public static let A4:PageSize = PageSize(size: .init(width: CGFloat(595), height: 842))
        
        /// A Letter page
        public static let letter:PageSize = PageSize(size: .init(width: CGFloat(612), height: 792))
        
        var pageSizeElement:AEXMLElement{
            return AEXMLElement(name: "w:pgSz", value: nil, attributes: ["w:w":String(width), "w:h":String(height), "w:orient":"landscape"])
        }
        
        /// The size of the page in points
        public var cgSize:CGSize{
            return size(unit: .points)
        }
        
        /// The size of the page in in a desired unit of length (cm, mm, inches, etc.)
        public func size(unit:UnitLength)->CGSize{
            return CGSize(width: Measurement(value: Double(width), unit: UnitLength.twips).converted(to: unit).value, height: Measurement(value: Double(width), unit: UnitLength.twips).converted(to: unit).value)
        }
    }
    
    /// The margins of a page (insets of the printable area).
    public struct PageMargins:Equatable, CustomStringConvertible, Hashable{
        
        /// Top margin in twips
        let top:Int
        
        /// bottom margin in twips.
        let bottom:Int
        
        /// left margin in twips
        let left:Int
        
        /// right margin in twips
        let right:Int
        
        /// footer margin in twips. The larger value of `bottom` or `footer` will be used
        let footer:Int
        
        /// header margin in twips. The larger value of `header` and `top` will be used.
        let header:Int
        
        /// memberwise initializer. All values are in twips (twentieth of an inch)
        /// - Parameters:
        ///     - top: top margin
        ///     - bottom: bottom margin
        ///     - left: left margin
        ///     - right: right margin
        ///     - footer: footer margin
        ///     - header: header margin
        init(top: Int, bottom: Int, left: Int, right: Int, footer: Int=0, header: Int=0) {
            self.top = top
            self.bottom = bottom
            self.left = left
            self.right = right
            self.footer = footer
            self.header = header
        }
        
        /// memberwise initializer. All values are in points. One inch (2.54 cm) is 72 points.
        /// - Parameters:
        ///     - top: top margin
        ///     - bottom: bottom margin
        ///     - left: left margin
        ///     - right: right margin
        ///     - footer: footer margin
        ///     - header: header margin
        public init(top:CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat, footer: CGFloat = 0, header: CGFloat = 0) {
            self.top = Int(Measurement(value: top, unit: UnitLength.points).converted(to: .twips).value)
            self.bottom = Int(Measurement(value: bottom, unit: UnitLength.points).converted(to: .twips).value)
            self.left = Int(Measurement(value: left, unit: UnitLength.points).converted(to: .twips).value)
            self.right = Int(Measurement(value: right, unit: UnitLength.points).converted(to: .twips).value)
            self.footer = Int(Measurement(value: footer, unit: UnitLength.points).converted(to: .twips).value)
            self.header = Int(Measurement(value: header, unit: UnitLength.points).converted(to: .twips).value)
        }
        
        /// Convenience initializer to define the margins size in length units (mm, cm, inches)
        public init(top:Measurement<UnitLength>, bottom: Measurement<UnitLength>, left: Measurement<UnitLength>, right: Measurement<UnitLength>, footer: Measurement<UnitLength> = Measurement(value: 0, unit: .centimeters), header: Measurement<UnitLength> = Measurement(value: 0, unit: .centimeters)){
            self.top = Int(top.converted(to: .twips).value)
            self.bottom = Int(bottom.converted(to: .twips).value)
            self.left = Int(left.converted(to: .twips).value)
            self.right = Int(right.converted(to: .twips).value)
            self.footer = Int(footer.converted(to: .twips).value)
            self.header = Int(header.converted(to: .twips).value)
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
            let top = top < 0 ? top : max(top, header)
            let bottom = bottom < 0 ? bottom : max(bottom, footer)
            return NSEdgeInsets(top: Measurement(value: Double(top), unit: UnitLength.twips).converted(to: unit).value, left: Measurement(value: Double(left), unit: UnitLength.twips).converted(to: unit).value, bottom: Measurement(value: Double(bottom), unit: UnitLength.twips).converted(to: unit).value, right: Measurement(value: Double(right), unit: UnitLength.twips).converted(to: unit).value)
        }
        
        public var description: String{
            let formatter=MeasurementFormatter()
            formatter.unitOptions = [.providedUnit]
            return "Top \(formatter.string(from: Measurement(value: Double(top), unit: UnitLength.twips).converted(to: .points))), bottom: \(formatter.string(from: Measurement(value: Double(bottom), unit: UnitLength.twips).converted(to: .points))), left: \(formatter.string(from: Measurement(value: Double(left), unit: UnitLength.twips).converted(to: .points))), right: \(formatter.string(from: Measurement(value: Double(right), unit: UnitLength.twips).converted(to: .points))), footer: \(formatter.string(from: Measurement(value: Double(footer), unit: UnitLength.twips).converted(to: .points))), header: \(formatter.string(from: Measurement(value: Double(header), unit: UnitLength.twips).converted(to: .points)))\rTop \(formatter.string(from: Measurement(value: Double(top), unit: UnitLength.twips).converted(to: .centimeters))), bottom: \(formatter.string(from: Measurement(value: Double(bottom), unit: UnitLength.twips).converted(to: .centimeters))), left: \(formatter.string(from: Measurement(value: Double(left), unit: UnitLength.twips).converted(to: .centimeters))), right: \(formatter.string(from: Measurement(value: Double(right), unit: UnitLength.twips).converted(to: .centimeters))), footer: \(formatter.string(from: Measurement(value: Double(footer), unit: UnitLength.twips).converted(to: .centimeters))), header: \(formatter.string(from: Measurement(value: Double(header), unit: UnitLength.twips).converted(to: .centimeters)))"
        }
        
        /// The default margins if a standard Word document.
        public static let `default` = PageMargins(top: CGFloat(72), bottom: 72, left: 72, right: 72, footer: 35.4, header: 35.4)
        
        var marginElement:AEXMLElement{
            return AEXMLElement(name: "w:pgMar", value: nil, attributes: ["w:top":String(top), "w:right":String(right), "w:bottom":String(bottom), "w:left":String(left), "w:header":String(header), "w:footer":String(footer), "w:gutter":"0"])
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
        return UnitLength(symbol: "points", converter: UnitConverterLinear(coefficient: 1/100 / 28.3465))
    }
    
    class var twips:UnitLength{
        return UnitLength(symbol: "twips", converter: UnitConverterLinear(coefficient: 1/100 / 28.3465 / 20))
    }
}

