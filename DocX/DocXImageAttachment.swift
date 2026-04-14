//
//  DocXImageAttachment.swift
//  DocX
//
//  NSTextAttachment subclass carrying DocX-specific image metadata.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// An `NSTextAttachment` subclass with DocX-specific image options
///
/// ```swift
/// let attachment = DocXImageAttachment(data: imageData, ofType: UTType.png.identifier)
/// attachment.imageWidthFraction = 0.5
/// attachment.imageFlow = .left
/// attachment.imageDescription = "A photo of a sunset"
/// let imageString = NSAttributedString(attachment: attachment)
/// ```
public class DocXImageAttachment: NSTextAttachment {
    
    /// Describes how text flows around an image in a Word document
    public enum Flow: Equatable {
        case left
        case right
    }

    /// The image width as a fraction of the printable column width
    /// When `nil`, the image uses its native dimensions (constrained to the page)
    public var imageWidthFraction: Double?

    /// How text flows around the image. When `nil`, the image is rendered inline
    /// Set to `.left` or `.right` to produce a floating image with square text wrapping
    public var imageFlow: Flow?

    /// Alt text for the image in the exported Word document
    public var imageDescription: String?
}
