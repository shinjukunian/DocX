//
//  DocXStyleConfiguration.swift
//  
//
//  Created by Brad Andalman on 2023/1/2.
//

import Foundation
import AEXML

/// Configuration parameters that control docx output
public struct DocXStyleConfiguration {
    /// The styles XML document to include
    public let stylesXMLDocument: AEXMLDocument?
    
    /// Should the font family be specified explicitly?
    /// This can come in handy when a client prefers that a font specified
    /// by a Word style (including the default "Normal" style) should be used.
    public let outputFontFamily: Bool
    
    /// Designated initializer that takes an AEXMLDocument for the `styles.xml` file
    public init(stylesXMLDocument: AEXMLDocument?, outputFontFamily: Bool = true) {
        self.stylesXMLDocument = stylesXMLDocument
        self.outputFontFamily = outputFontFamily
    }
    
    /// Convenience initializer that takes a URL to the `styles.xml` file
    public init(stylesXMLURL: URL? = nil, outputFontFamily: Bool = true) throws {
        let xmlDocument: AEXMLDocument?
        if let xmlURL = stylesXMLURL {
            let xmlData = try Data(contentsOf: xmlURL)
            xmlDocument = try AEXMLDocument(xml: xmlData,
                                            options: DocXStyleConfiguration.xmlOptions)
        } else {
            xmlDocument = nil
        }

        self.init(stylesXMLDocument: xmlDocument, outputFontFamily: outputFontFamily)
    }
    
    /// Convenience initializer that takes a string for the `styles.xml` file
    public init(stylesXMLString: String? = nil, outputFontFamily: Bool = true) throws {
        let xmlDocument: AEXMLDocument?
        if let xmlString = stylesXMLString {
            xmlDocument = try AEXMLDocument(xml: xmlString,
                                            options: DocXStyleConfiguration.xmlOptions)
        } else {
            xmlDocument = nil
        }
        
        self.init(stylesXMLDocument: xmlDocument, outputFontFamily: outputFontFamily)
    }
    
    /// Returns the AEXML options used to create an AEXMLDocument
    private static var xmlOptions: AEXMLOptions = {
        var options = AEXMLOptions()
        options.parserSettings.shouldTrimWhitespace=false
        options.documentHeader.standalone="yes"
        
        // Enable escaping so that reserved characters, like < & >, don't
        // result in an invalid docx file
        // See: https://github.com/shinjukunian/DocX/issues/24
        options.escape = true
        
        return options
    }()
}
