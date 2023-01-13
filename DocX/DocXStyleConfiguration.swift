//
//  DocXStyleConfiguration.swift
//  
//
//  Created by Brad Andalman on 2023/1/2.
//

import Foundation
import AEXML

/// Configuration parameters that control docx styling.
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
    
    /// The paragraph styles that were found in the `styles.xml` file during initialization. Use with `NSAttributedString.Key.paragraphId`.
    public var availableParagraphStyles:[String]?{
        return self.stylesXMLDocument?.root.children.filter({element in
            element.name == "w:style" && element.attributes["w:type"] == "paragraph"
        }).compactMap({$0.attributes["w:styleId"]})
    }
    
    /// The character styles that were found in the `styles.xml` file during initialization. Use with `NSAttributedString.Key.characterId`.
    public var availableCharacterStyles:[String]?{
        return self.stylesXMLDocument?.root.children.filter({element in
            element.name == "w:style" && element.attributes["w:type"] == "character"
        }).compactMap({$0.attributes["w:styleId"]})
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
