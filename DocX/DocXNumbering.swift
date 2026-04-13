//
//  DocXNumbering.swift
//  DocX
//
//  Provides native Word list numbering support.
//

import AEXML
import AppKit
import Foundation

/// Describes the visual style of a list numbering definition
/// Each case must be a valid `numFmt`, as specified in the OOXML spec
/// (though this is not everything that OOXML supports)
public enum DocXListStyle: Int, Hashable, Comparable {
    /// Bulleted list (•, ◦, ▪, repeating...)
    case bullet
    /// Decimal numbering (1, 2, 3, ...)
    case decimal
    /// Lowercase letter (a, b, c, ...)
    case lowerLetter
    /// Uppercase letter (A, B, C, ...)
    case upperLetter
    /// Lowercase Roman numeral (i, ii, iii, ...)
    case lowerRoman
    /// Uppercase Roman numeral (I, II, III, ...)
    case upperRoman

    public static func < (lhs: DocXListStyle, rhs: DocXListStyle) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    fileprivate var numFmtValue: String {
        switch self {
        case .bullet:
            return "bullet"
        case .decimal:
            return "decimal"
        case .lowerLetter:
            return "lowerLetter"
        case .upperLetter:
            return "upperLetter"
        case .lowerRoman:
            return "lowerRoman"
        case .upperRoman:
            return "upperRoman"
        }
    }
    
    // Defines a mapping from NSParagraphStyle attributes to DocX ones
    private static let markerFormatMapping: [(NSTextList.MarkerFormat, DocXListStyle)] = [
        (.decimal, .decimal),
        (.lowercaseLatin, .lowerLetter),
        (.lowercaseRoman, .lowerRoman),
        (.uppercaseRoman, .upperRoman),
        (.uppercaseLatin, .upperLetter),
    ]

    // Initializer that creates a DocXListStyle from an NSText.MarkerFormat
    init(markerFormat: NSTextList.MarkerFormat) {
        switch markerFormat {
        case .decimal:
            self = .decimal
        case .lowercaseLatin:
            self = .lowerLetter
        case .lowercaseRoman:
            self = .lowerRoman
        case .uppercaseLatin:
            self = .upperLetter
        case .uppercaseRoman:
            self = .upperRoman
        default:
            // Everything else uses bullet
            self = .bullet
        }
    }
}

/// Describes one Word numbering definition keyed by `numId`.
///
/// A numbering definition can vary its visual style by indent level, so this
/// type stores the list style seen at each level and can answer which style
/// should be used for any requested level.
private struct NumberingDefinition {
    let numId: Int
    private(set) var stylesByLevel: [Int: DocXListStyle] = [:]

    /// Records the list style used at a given indent level.
    ///
    /// The first style seen for a level wins so later paragraphs in the same
    /// numbering definition don't accidentally redefine it.
    mutating func register(style: DocXListStyle, level: Int) {
        if stylesByLevel[level] == nil {
            stylesByLevel[level] = style
        }
    }

    /// Returns the list style that should be used for `level`.
    ///
    /// If no explicit style was recorded for that level, this falls back to the
    /// nearest shallower level, then finally to level 0 or `.bullet`.
    func style(for level: Int) -> DocXListStyle {
        if let style = stylesByLevel[level] {
            return style
        }

        // Iterate backward from (level - 1) to 0
        for fallbackLevel in stride(from: level - 1, through: 0, by: -1) {
            if let style = stylesByLevel[fallbackLevel] {
                return style
            }
        }

        return stylesByLevel[0] ?? .bullet
    }
}

/// Collects list numbering information from paragraph attributes and generates
/// `numbering.xml`
///
/// During docx writing, each paragraph's `.listNumberingId`, `.listNumberingLevel`,
/// and `.listStyle` attributes are collected. The numbering configuration then
/// generates abstract numbering definitions and concrete numbering instances.
struct DocXNumberingConfiguration {

    /// Maps each numId to its numbering definition.
    private var numberingDefinitions: [Int: NumberingDefinition] = [:]

    /// Whether any numbering definitions have been collected.
    var hasNumbering: Bool { !numberingDefinitions.isEmpty }

    /// Records that a given numId uses a particular list style at a particular level.
    mutating func register(numId: Int, style: DocXListStyle, level: Int) {
        var definition = numberingDefinitions[numId] ?? NumberingDefinition(numId: numId)
        definition.register(style: style, level: level)
        numberingDefinitions[numId] = definition
    }

    // MARK: - Indentation Configuration
    
    // The following values are hard-coded
    // (though could be exposed, if desired)

    /// Base left margin in points (0.4 inches = 28.8pt)
    let baseLeftMarginPt: Double = 0.4 * 72.0

    /// Additional indent per sub-level in points
    let subLevelIndentPt: Double = 20.0

    /// Maximum number of levels (0-based)
    let maxLevel: Int = 8

    /// The hanging indent as a fraction of baseLeftMarginPt
    let hangingIndentFraction: Double = 0.5

    // MARK: - XML Generation

    /// Generates the complete `numbering.xml` content
    func numberingXML() -> String {
        var options = AEXMLOptions()
        options.documentHeader.standalone = "yes"
        options.documentHeader.encoding = "UTF-8"
        options.escape = true
        options.lineSeparator = "\n"

        let root = AEXMLElement(name: "w:numbering",
                                value: nil,
                                attributes: [
                                    "xmlns:wpc": "http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas",
                                    "xmlns:mc": "http://schemas.openxmlformats.org/markup-compatibility/2006",
                                    "xmlns:o": "urn:schemas-microsoft-com:office:office",
                                    "xmlns:r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
                                    "xmlns:m": "http://schemas.openxmlformats.org/officeDocument/2006/math",
                                    "xmlns:v": "urn:schemas-microsoft-com:vml",
                                    "xmlns:wp": "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing",
                                    "xmlns:w10": "urn:schemas-microsoft-com:office:word",
                                    "xmlns:w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
                                    "xmlns:wne": "http://schemas.microsoft.com/office/word/2006/wordml",
                                    "mc:Ignorable": ""
                                ])
        let document = AEXMLDocument(root: root, options: options)

        for definition in numberingDefinitions.values.sorted(by: { $0.numId < $1.numId }) {
            root.addChild(abstractNumElement(definition: definition))
        }

        for definition in numberingDefinitions.values.sorted(by: { $0.numId < $1.numId }) {
            let numElement = AEXMLElement(name: "w:num",
                                          value: nil,
                                          attributes: ["w:numId": "\(definition.numId)"])
            numElement.addChild(AEXMLElement(name: "w:abstractNumId",
                                             value: nil,
                                             attributes: ["w:val": "\(definition.numId)"]))
            root.addChild(numElement)
        }

        return document.xmlCompact
    }

    /// Generates the XML for the abstract numbering definition for `numId`.
    private func abstractNumElement(definition: NumberingDefinition) -> AEXMLElement {
        let abstractNumElement = AEXMLElement(name: "w:abstractNum",
                                              value: nil,
                                              attributes: ["w:abstractNumId": "\(definition.numId)"])
        abstractNumElement.addChild(AEXMLElement(name: "w:multiLevelType",
                                                 value: nil,
                                                 attributes: ["w:val": "hybridMultilevel"]))

        for level in 0...maxLevel {
            abstractNumElement.addChild(levelElement(listStyle: definition.style(for: level), level: level))
        }

        return abstractNumElement
    }

    /// Generates the XML for a single level in `listStyle`
    private func levelElement(listStyle: DocXListStyle, level: Int) -> AEXMLElement {
        let isBulleted = (listStyle == .bullet)

        // Compute indentation in twips (1pt = 20 twips)
        let hangingPt = floor(hangingIndentFraction * baseLeftMarginPt)
        let firstLineHeadIndentPt = baseLeftMarginPt + subLevelIndentPt * Double(level)
        let textStartLocationPt = firstLineHeadIndentPt + hangingPt

        let leftTwips = Int(round(textStartLocationPt * 20.0))
        let hangingTwips = Int(round(hangingPt * 20.0))

        let levelElement = AEXMLElement(name: "w:lvl",
                                        value: nil,
                                        attributes: ["w:ilvl": "\(level)"])
        levelElement.addChild(AEXMLElement(name: "w:start",
                                           value: nil,
                                           attributes: ["w:val": "1"]))

        if isBulleted {
            let bulletChar: String
            let fontName: String
            switch level % 3 {
            case 0:
                bulletChar = "\u{F0B7}"
                fontName = "Symbol"
            case 1:
                bulletChar = "o"
                fontName = "Courier New"
            default:
                bulletChar = "\u{F0A7}"
                fontName = "Wingdings"
            }

            levelElement.addChild(AEXMLElement(name: "w:numFmt",
                                               value: nil,
                                               attributes: ["w:val": "bullet"]))
            levelElement.addChild(AEXMLElement(name: "w:lvlText",
                                               value: nil,
                                               attributes: ["w:val": bulletChar]))
            levelElement.addChild(AEXMLElement(name: "w:lvlJc",
                                               value: nil,
                                               attributes: ["w:val": "left"]))

            let paragraphProperties = AEXMLElement(name: "w:pPr")
            paragraphProperties.addChild(AEXMLElement(name: "w:ind",
                                                      value: nil,
                                                      attributes: [
                                                          "w:left": "\(leftTwips)",
                                                          "w:hanging": "\(hangingTwips)"
                                                      ]))
            levelElement.addChild(paragraphProperties)

            let runProperties = AEXMLElement(name: "w:rPr")
            runProperties.addChild(AEXMLElement(name: "w:rFonts",
                                                value: nil,
                                                attributes: [
                                                    "w:ascii": fontName,
                                                    "w:hAnsi": fontName,
                                                    "w:hint": "default"
                                                ]))
            levelElement.addChild(runProperties)
        } else {
            // Level is zero-based
            let lvlText = "%\(level + 1)."

            levelElement.addChild(AEXMLElement(name: "w:numFmt",
                                               value: nil,
                                               attributes: ["w:val": listStyle.numFmtValue]))
            levelElement.addChild(AEXMLElement(name: "w:lvlText",
                                               value: nil,
                                               attributes: ["w:val": lvlText]))
            levelElement.addChild(AEXMLElement(name: "w:lvlJc",
                                               value: nil,
                                               attributes: ["w:val": "left"]))

            let paragraphProperties = AEXMLElement(name: "w:pPr")
            paragraphProperties.addChild(AEXMLElement(name: "w:ind",
                                                      value: nil,
                                                      attributes: [
                                                          "w:left": "\(leftTwips)",
                                                          "w:hanging": "\(hangingTwips)"
                                                      ]))
            levelElement.addChild(paragraphProperties)
        }

        return levelElement
    }
}
