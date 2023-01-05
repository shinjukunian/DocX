//
//  DocXConfiguration.swift
//  
//
//  Created by Brad Andalman on 2023/1/2.
//

import Foundation

/// Configuration parameters that control docx output
public struct DocXConfiguration {
    /// The URL for the styles XML file to include
    public let stylesURL: URL?
    
    /// Should the font family be specified explicitly?
    /// This can come in handy when a client prefers that a font specified
    /// by a Word style (including the default "Normal" style) should be used.
    public let outputFontFamily: Bool
    
    /// Memberwise initializer
    public init(stylesURL: URL? = nil, outputFontFamily: Bool = true) {
        self.stylesURL = stylesURL
        self.outputFontFamily = outputFontFamily
    }
}
