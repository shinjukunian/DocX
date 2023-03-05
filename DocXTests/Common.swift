//
//  Common.swift
//  
//
//  Created by Morten Bertz on 2023/03/05.
//

import Foundation
import DocX
import XCTest

// XXX This currently only lists a small subset of possible errors
//     It would be nice to list all possible errors here
public enum TestError: Error {
    // Error thrown when the expected link text isn't found in the given string
    case couldNotFindLinkTitle
    
    // Error thrown when validating the docx fails
    case validationFailed
}

public protocol DocXTesting{
    
    /// This function tests writing a docx file using the *DocX* exporter
    /// Optionally, options may be passed
    func writeAndValidateDocX(attributedString: NSAttributedString,
                              options: DocXOptions) throws
    
    /// This function tests writing a docx file using the macOS builtin exporter
    func writeAndValidateDocXUsingBuiltIn(attributedString: NSAttributedString) throws
    
    /// Returns a basename that can be used when exporting a docx
    func docxBasename(attributedString: NSAttributedString) -> String
    
    /// Performs a very simply validation of the docx file by reading it
    /// in and making sure the document type is OOXML
    func validateDocX(url: URL) throws
    
    /// The URL to store the generated .docx files
    var tempURL:URL { get}
    
    /// The bundle where to find the test resources
    var bundle:Bundle { get}
    
}


extension DocXTesting{
    
    public var bundle: Bundle {
#if SWIFT_PACKAGE
        return Bundle.module
#elseif os(macOS)
        return Bundle(for: DocXTests.self)
#else
        return Bundle(for: DocX_iOS_Tests.self)
#endif
    }

    
    public func docxBasename(attributedString: NSAttributedString) -> String {
        return UUID().uuidString + "_myDocument_\(attributedString.string.prefix(10))"
    }


    public func writeAndValidateDocX(attributedString: NSAttributedString,
                              options: DocXOptions = DocXOptions()) throws {
        let url = self.tempURL.appendingPathComponent(docxBasename(attributedString: attributedString)).appendingPathExtension("docx")
        try attributedString.writeDocX(to: url, options: options)
        // Validate that writing was successful
        try validateDocX(url: url)
    }

    public func writeAndValidateDocXUsingBuiltIn(attributedString: NSAttributedString) throws {
        let url = self.tempURL.appendingPathComponent(docxBasename(attributedString: attributedString)).appendingPathExtension("docx")
        #if canImport(AppKit)
        try attributedString.writeDocX(to: url, useBuiltIn: true)
        #else
        try attributedString.writeDocX(to: url)
        #endif
        
        // Validate that writing was successful
        try validateDocX(url: url)
    }

#if canImport(AppKit)
    public func validateDocX(url: URL) throws {
        // Read the string from the URL
        var readAttributes:NSDictionary?
        let _ = try NSAttributedString(url: url, options: [:], documentAttributes: &readAttributes)
        
        // Make sure we read the document attributes
        guard let attributes = readAttributes as? [String:Any] else {
            throw TestError.validationFailed
        }
        
        // The document type should be OOXML
        XCTAssertEqual(attributes[NSAttributedString.DocumentAttributeKey.documentType.rawValue] as! String,
                       NSAttributedString.DocumentType.officeOpenXML.rawValue)
    }
    
#else
    public func validateDocX(url: URL) throws {}
#endif
}




