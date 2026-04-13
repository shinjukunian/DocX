//
//  DocXTests.swift
//  DocXTests
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

#if os(macOS)
import XCTest
@testable import DocX
import AppKit

#if(canImport(UniformTypeIdentifiers))
import UniformTypeIdentifiers
#endif

#if(canImport(SwiftUI))
import SwiftUI
#endif

class DocXTests: XCTestCase {
    
    // XXX This currently only lists a small subset of possible errors
    //     It would be nice to list all possible errors here
    enum TestError: Error {
        // Error thrown when the expected link text isn't found in the given string
        case couldNotFindLinkTitle
        
        // Error thrown when validating the docx fails
        case validationFailed
    }

    
#if SWIFT_PACKAGE
        let bundle=Bundle.module
#else
        let bundle=Bundle(for: DocXTests.self)
#endif

    var tempURL:URL=URL(fileURLWithPath: "")
    
    
    override func setUp() {
        let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        do{
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
            self.tempURL=url
        }
        catch let error{
            print(error)
            XCTFail()
        }
        
    }
    
    override func tearDown() {
        do{
            try FileManager.default.removeItem(at: self.tempURL)
        }
        catch let error{
            print(error)
            XCTFail()
        }
    }
    
    /// Returns a basename that can be used when exporting a docx
    private func docxBasename(attributedString: NSAttributedString) -> String {
        return UUID().uuidString + "_myDocument_\(attributedString.string.prefix(10))"
    }
    
    /// This function tests writing a docx file using the *DocX* exporter
    /// Optionally, options may be passed
    func writeAndValidateDocX(attributedString: NSAttributedString,
                              options: DocXOptions = DocXOptions()) throws {
        let url = self.tempURL.appendingPathComponent(docxBasename(attributedString: attributedString)).appendingPathExtension("docx")
        try attributedString.writeDocX(to: url, options: options)
        // Validate that writing was successful
        try validateDocX(url: url)
    }

    func writeAndValidateSections(_ sections: [NSAttributedString],
                                  options: DocXOptions = DocXOptions()) throws {
        let basename = sections.first.map(docxBasename(attributedString:)) ?? UUID().uuidString
        let url = self.tempURL.appendingPathComponent(basename).appendingPathExtension("docx")
        try DocXWriter.write(sections: sections, to: url, options: options)
        try validateDocX(url: url)
    }
    
    /// This function tests writing a docx file using the macOS builtin exporter
    func writeAndValidateDocXUsingBuiltIn(attributedString: NSAttributedString) throws {
        let url = self.tempURL.appendingPathComponent(docxBasename(attributedString: attributedString)).appendingPathExtension("docx")
        try attributedString.writeDocX(to: url, useBuiltIn: true)
        
        // Validate that writing was successful
        try validateDocX(url: url)
    }
    
    /// Performs a very simply validation of the docx file by reading it
    /// in and making sure the document type is OOXML
    func validateDocX(url: URL) throws {
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
    
    func testEscapedCharacters() throws {
        let string="\"You done messed up A'Aron!\" <Key & Peele>"
        let attributedString=NSAttributedString(string: string)
        
        // Though we set the author and title here, we don't actually
        // test that they are properly escaped in the docx file.
        // It might be nice to do that.
        var docxOptions = DocXOptions()
        docxOptions.author = "<Key & Peele>"
        docxOptions.title = "\"Key & Peele's Show\""
        
        try writeAndValidateDocX(attributedString: attributedString, options: docxOptions)
    }
    
    func testBlank() throws {
        let string=""
        let attributedString=NSAttributedString(string: string)

        try writeAndValidateDocX(attributedString: attributedString)
    }

    func test山田Plain() throws {
        let string="山田"
        try writeAndValidateDocX(attributedString: NSAttributedString(string: string))
    }

    func test山田Attributed() throws {
        let string="山田"
        let attributed=NSAttributedString(string: string, attributes: [.font:NSFont.systemFont(ofSize: NSFont.systemFontSize)])
        try writeAndValidateDocX(attributedString: attributed)
    }

    func test山田FuriganaAttributed() throws {
        let string="山田"
        let furigana="やまだ"
        let ruby=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, furigana as CFString, [kCTRubyAnnotationSizeFactorAttributeName:0.5] as CFDictionary)
        let rubyKey=NSAttributedString.Key(kCTRubyAnnotationAttributeName as String)
        let attributed=NSAttributedString(string: string, attributes: [.font:NSFont.systemFont(ofSize: NSFont.systemFontSize), rubyKey:ruby])
        try writeAndValidateDocX(attributedString: attributed)
    }


    var yamadaDenkiString:NSMutableAttributedString{
        let string="山田電気"
        let furigana="やまだ"
        let sizeFactorDictionary=[kCTRubyAnnotationSizeFactorAttributeName:0.5] as CFDictionary
        let yamadaRuby=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, furigana as CFString, sizeFactorDictionary)

        let rubyKey=NSAttributedString.Key(kCTRubyAnnotationAttributeName as String)
        let attributedString=NSMutableAttributedString(string: string, attributes: [.font:NSFont.systemFont(ofSize: NSFont.systemFontSize), .foregroundColor:NSColor.red])
        attributedString.addAttributes([rubyKey:yamadaRuby], range: NSRange(location: 0, length: 2))
        let denkiRuby=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, "でんき" as CFString, sizeFactorDictionary)
        attributedString.addAttributes([rubyKey:denkiRuby], range: NSRange(location: 2, length: 2))
        return attributedString
    }

    func test山田電気FuriganaAttributed() throws {
        try writeAndValidateDocX(attributedString: yamadaDenkiString)
    }

    func test山田電気FuriganaAttributed_ParagraphStyle() throws {
        let attributed=yamadaDenkiString
        let style=NSParagraphStyle.default
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        try writeAndValidateDocX(attributedString: attributed)

    }

    func test山田電気FuriganaAttributed_ParagraphStyle_vertical() throws {
        let attributed=yamadaDenkiString
        let style=NSParagraphStyle.default
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        attributed.addAttribute(.verticalForms, value: true, range:NSRange(location: 0, length: attributed.length))
        try writeAndValidateDocX(attributedString: attributed)
    }

    func test山田電気FuriganaAttributed_ParagraphStyle_bold() throws {
        let attributed=yamadaDenkiString
        let style=NSParagraphStyle.default
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let boldFont=NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        attributed.addAttribute(.font, value: boldFont, range: NSRange(location: 0, length: 2))
        try writeAndValidateDocX(attributedString: attributed)

    }

    //crashes the cocoa docx writer!
    func test山田電気FuriganaAttributed_ParagraphStyle_underline() throws {
        let attributed=yamadaDenkiString
//        let style=NSParagraphStyle.default
//        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let underlineStyle:NSUnderlineStyle = .single
        attributed.addAttribute(.underlineStyle, value: underlineStyle.rawValue, range:NSRange(location: 0, length: attributed.length))
        try writeAndValidateDocX(attributedString: attributed)
    }

    func test山田電気FuriganaAttributed_ParagraphStyle_backgroundColor() throws {
        let attributed=yamadaDenkiString
        let style=NSMutableParagraphStyle()
        style.setParagraphStyle(NSParagraphStyle.default)
        style.alignment = .center
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))

        attributed.addAttribute(.backgroundColor, value: NSColor.blue, range:NSRange(location: 0, length: attributed.length))
        try writeAndValidateDocX(attributedString: attributed)

    }
    func test山田電気FuriganaAttributed_ParagraphStyle_strikethrough() throws {
        let attributed=yamadaDenkiString
        //        let style=NSParagraphStyle.default
        //        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let underlineStyle:NSUnderlineStyle = [.single]
        attributed.addAttribute(.strikethroughStyle, value: underlineStyle.rawValue, range:NSRange(location: 0, length: attributed.length))
        try writeAndValidateDocX(attributedString: attributed)
        
        sleep(1)
    }
    
    /// Helper method for creating links in an attributed string
    private func createLinkInAttributedString(_ attributedString: NSAttributedString,
                                              linkTitle: String,
                                              url: URL) throws -> NSAttributedString {
        // Search for `linkTitle` in the attributed string
        guard let linkRange = attributedString.string.range(of: linkTitle) else {
            throw TestError.couldNotFindLinkTitle
        }
        
        // Apply the .link attribute to the link range
        let newString = NSMutableAttributedString(attributedString: attributedString)
        let range = NSRange(linkRange, in:attributedString.string)
        newString.addAttribute(.link, value: url, range: range)
        
        return newString
    }
    
    func testLinkFuriganaAttributed() throws {
        let rakutenLinkText = "https://www.rakuten-sec.co.jp/"
        let string="楽天 \(rakutenLinkText)"
        let attributed=NSMutableAttributedString(string: string)
        attributed.addAttributes([.font:NSFont.systemFont(ofSize: NSFont.systemFontSize)], range: NSRange(location: 0, length: attributed.length))
        let furigana="らくてん"
        let furiganaAnnotation=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, furigana as CFString, [kCTRubyAnnotationSizeFactorAttributeName:0.5] as CFDictionary)
        attributed.addAttribute(.ruby, value: furiganaAnnotation, range: NSRange(location: 0, length: 2))
        
        // Format the link in the string
        let linkString = try createLinkInAttributedString(attributed,
                                                          linkTitle: rakutenLinkText,
                                                          url: URL(string:rakutenLinkText)!)
        
        try writeAndValidateDocX(attributedString: linkString)
    }
        
    func testLinks() throws {
        // Helper struct that contains all of the information necessary
        // to apply a `url` to the `linkTitle` in an `attributedString`
        struct LinkStringInfo {
            let attributedString: NSAttributedString
            let linkTitle: String
            let url: URL
            
            init(string: String, linkTitle: String, urlString: String) {
                self.attributedString = NSAttributedString(string: string)
                self.linkTitle = linkTitle
                self.url = URL(string: urlString)!
            }
        }
        
        // Build up a list of URLs to test
        let infoList = [LinkStringInfo(string: "This is a simple [link]",
                                       linkTitle: "[link]",
                                       urlString:"https://example.com"),
                        
                        LinkStringInfo(string: "This is a [link] with a fragment",
                                       linkTitle: "[link]",
                                       urlString: "https://example.com/#fragment"),
                        
                        LinkStringInfo(string: "This [link] has one kwparam",
                                       linkTitle: "[link]",
                                       urlString: "https://example.com/?fc=us"),
                        
                        LinkStringInfo(string: "This [link] has multiple kwparams",
                                       linkTitle: "[link]",
                                       urlString: "https://example.com/?fc=us&ds=1"),
        ]
        
        let newline = NSAttributedString(string:"\n")

        // Iterate over the info list, construct a properly formatted link string,
        // and then append that link string to the output string
        let outputString = NSMutableAttributedString()
        for info in infoList {
            let linkString = try createLinkInAttributedString(info.attributedString,
                                                              linkTitle: info.linkTitle,
                                                              url: info.url)
            outputString.append(linkString)
            outputString.append(newline)
        }
        
        try writeAndValidateDocX(attributedString: outputString)
    }
    
    func test_ParagraphStyle() throws {
        let string =
        """
This property contains the space (measured in points) added at the end of the paragraph to separate it from the following paragraph. This value is always nonnegative. The space between paragraphs is determined by adding the previous paragraph’s paragraphSpacing and the current paragraph’s paragraphSpacingBefore.
Specifies the border displayed above a set of paragraphs which have the same set of paragraph border settings. Note that if the adjoining paragraph has identical border settings and a between border is specified, a single between border will be used instead of the bottom border for the first and a top border for the second.
"""
        
        let style=NSMutableParagraphStyle()
        style.setParagraphStyle(NSParagraphStyle.default)
        style.alignment = .left
        style.paragraphSpacing=20
        style.lineHeightMultiple=1.5
        //style.firstLineHeadIndent=20
        style.headIndent=20
        style.tailIndent=20
        
        let font=NSFont(name: "Helvetica", size: 13) ?? NSFont.systemFont(ofSize: 13)
        
        let attributed=NSMutableAttributedString(string: string, attributes: [.paragraphStyle:style, .font:font])
        try writeAndValidateDocX(attributedString: attributed)
    }
    
    func testOutline() throws {
        let outlineString=NSAttributedString(string: "An outlined String\r", attributes: [.font:NSFont.systemFont(ofSize: 13),.strokeWidth:3,.strokeColor:NSColor.green, .foregroundColor:NSColor.blue, .backgroundColor:NSColor.orange])
        let outlinedAndStroked=NSMutableAttributedString(attributedString: outlineString)
        outlinedAndStroked.addAttribute(.strokeWidth, value: -3, range: NSRange(location: 0, length: outlinedAndStroked.length))
        let noBG=NSMutableAttributedString(attributedString: outlineString)
        noBG.removeAttribute(.backgroundColor, range: NSMakeRange(0, noBG.length))
        noBG.append(outlinedAndStroked)
        noBG.append(outlineString)
        
        try writeAndValidateDocX(attributedString: noBG)
    }
    
    func testComposite() throws {
        let rootAttributedString = NSMutableAttributedString()
        
        rootAttributedString.append(NSAttributedString(string: "blah blah blah 1 ... but more text"))
        rootAttributedString.append(NSAttributedString(string: "blah blah blah 2 ... more text here also"))
        
        try writeAndValidateDocXUsingBuiltIn(attributedString: rootAttributedString)
    }
    
    func testMultipage() throws {
        let longString = """
            1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            2. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            3. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            4. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            5. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            """
        let attributed=NSAttributedString(string: longString, attributes: [.font:NSFont.systemFont(ofSize: 20)])
        try writeAndValidateDocXUsingBuiltIn(attributedString: attributed)
    }
    
    func testImage() throws {
        let longString = """
            1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        let imageURL=URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Picture1.png")
        let imageData=try XCTUnwrap(Data(contentsOf: imageURL), "Image not found")
        let attachement=NSTextAttachment(data: imageData, ofType: UTType.png.identifier)
        let attributed=NSAttributedString(string: longString, attributes: [.foregroundColor: NSColor.green])
        let imageString=NSAttributedString(attachment: attachement)
        let result=NSMutableAttributedString()
        result.append(attributed)
        result.append(imageString)
        try writeAndValidateDocX(attributedString: result)
    }
    
    func testImageAndLink() throws{
        let longString = """
        1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        let imageURL=URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Picture1.png")
        let imageData=try XCTUnwrap(Data(contentsOf: imageURL), "Image not found")
        let attachement=NSTextAttachment(data: imageData, ofType: UTType.png.identifier)
        let attributed=NSMutableAttributedString(string: longString, attributes: [:])
        attributed.addAttributes([.link:URL(string: "http://officeopenxml.com/index.php")!], range: NSRange(location: 2, length: 6))
        let imageString=NSAttributedString(attachment: attachement)
        let result=NSMutableAttributedString()
        result.append(attributed)
        result.append(imageString)
        try writeAndValidateDocX(attributedString: result)
    }
    
    func test2Images() throws{
        let longString = """
        1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum\r.
        """
        let imageURL=URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Picture1.png")
        let imageData=try XCTUnwrap(Data(contentsOf: imageURL), "Image not found")
        let attachement=NSTextAttachment(data: imageData, ofType: UTType.png.identifier)
        let attributed=NSMutableAttributedString(string: longString, attributes: [:])
        attributed.addAttributes([.link:URL(string: "http://officeopenxml.com/index.php")!], range: NSRange(location: 2, length: 6))
        let imageString=NSAttributedString(attachment: attachement)
        let result=NSMutableAttributedString()
        result.append(attributed)
        result.append(imageString)
        result.append(attributed)
        result.append(imageString)
        result.append(attributed)
        try writeAndValidateDocX(attributedString: result)
    }
    
    func testMultiPage() throws {
        let string =
        """
This property contains the space (measured in points) added at the end of the paragraph to separate it from the following paragraph. This value is always nonnegative. The space between paragraphs is determined by adding the previous paragraph’s paragraphSpacing and the current paragraph’s paragraphSpacingBefore.
Specifies the border displayed above a set of paragraphs which have the same set of paragraph border settings. Note that if the adjoining paragraph has identical border settings and a between border is specified, a single between border will be used instead of the bottom border for the first and a top border for the second.
"""
        
       
        let font=NSFont(name: "Helvetica", size: 13) ?? NSFont.systemFont(ofSize: 13)
        
        let attributed=NSMutableAttributedString(string: string, attributes: [.font:font])
        let attr_break=NSAttributedString(string: "\r", attributes: [.breakType:BreakType.page])
        
        let result=NSMutableAttributedString()
        result.append(attributed)
        result.append(attr_break)
        result.append(attributed)
        
        try writeAndValidateDocX(attributedString: result)
    }
    
    func testMultiPageWriter() throws{
        // added parahraph breaks at the end to catch a bug reported by andalman
        //https://github.com/shinjukunian/DocX/issues/14
        let string =
        """
This property contains the space (measured in points) added at the end of the paragraph to separate it from the following paragraph. This value is always nonnegative. The space between paragraphs is determined by adding the previous paragraph’s paragraphSpacing and the current paragraph’s paragraphSpacingBefore.
Specifies the border displayed above a set of paragraphs which have the same set of paragraph border settings. Note that if the adjoining paragraph has identical border settings and a between border is specified, a single between border will be used instead of the bottom border for the first and a top border for the second.


"""
        
       
        let font=NSFont(name: "Helvetica", size: 13) ?? NSFont.systemFont(ofSize: 13)
        
        let attributed=NSMutableAttributedString(string: string, attributes: [.font:font])
        
        let numPages=10
        
        let pages=Array(repeating: attributed, count: numPages)
        
        let url=self.tempURL.appendingPathComponent(UUID().uuidString + "_myDocument_\(attributed.string.prefix(10))").appendingPathExtension("docx")
        
        try DocXWriter.write(pages: pages, to: url)
        try validateDocX(url: url)
    }
    
    func testImageAndLinkMetaData() throws {
        let longString = """
        1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        let imageURL=URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("Picture1.png")
        let imageData=try XCTUnwrap(Data(contentsOf: imageURL), "Image not found")
        let attachement=NSTextAttachment(data: imageData, ofType: UTType.png.identifier)
        let attributed=NSMutableAttributedString(string: longString, attributes: [:])
        attributed.addAttributes([.link:URL(string: "http://officeopenxml.com/index.php")!], range: NSRange(location: 2, length: 6))
        let imageString=NSAttributedString(attachment: attachement)
        let result=NSMutableAttributedString()
        result.append(attributed)
        result.append(imageString)
        
        var options=DocXOptions()
        options.author="Barack Obama"
        options.createdDate = .init(timeIntervalSinceNow: -100000)
        options.keywords=["Lorem", "Ipsum", "a longer keyword"]
        options.description="Take a bike out for a spin"
        options.title="Lorem Ipsum String + Image"
        options.subject="Test Metadata"
        
        try writeAndValidateDocX(attributedString: result, options: options)
    }
    
    func testMichaelKnight() throws {
        let font = NSFont(name: "Helvetica", size: 13)!
        let string = NSAttributedString(string: "The Foundation For Law and Government favours Helvetica.", attributes: [.font: font])

        var options = DocXOptions()
        options.author = "Michael Knight"
        options.title = "Helvetica Document"

        try writeAndValidateDocX(attributedString: string, options: options)
    }
    
    func testLenna_size() throws {
        let longString = """
        1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum\r.
        """
        
        let imageURL=try XCTUnwrap(bundle.url(forResource: "lenna", withExtension: "png"), "ImageURL not found")
        
        let imageData=try XCTUnwrap(Data(contentsOf: imageURL), "Image not found")
        let attachement=NSTextAttachment(data: imageData, ofType: UTType.png.identifier)
        attachement.bounds=CGRect(x: 0, y: 0, width: 128, height: 128)
        
        let attributed=NSMutableAttributedString(string: longString, attributes: [:])
//        attributed.addAttributes([.link:URL(string: "http://officeopenxml.com/index.php")!], range: NSRange(location: 2, length: 6))
        let imageString=NSAttributedString(attachment: attachement)
        let result=NSMutableAttributedString()
        result.append(attributed)
        result.append(imageString)
        result.append(attributed)
//        result.append(attributed)
        try writeAndValidateDocX(attributedString: result)
    }
    
    @available(macOS 12, *)
    func testAttributed() throws {
        let font = try XCTUnwrap(NSFont(name: "Helvetica", size: 12))
        var att=AttributedString(NSAttributedString(string: "Lorem ipsum dolor sit amet", attributes: [.font: font]))
        var attributes = AttributeContainer()
        attributes.appKit.strokeColor = .green
        attributes.appKit.strokeWidth = -2
        attributes.appKit.foregroundColor = .gray
        att.mergeAttributes(attributes)
        
        try writeAndValidateDocX(attributedString: NSAttributedString(att))
    }
    
    
    @available(macOS 12, *)
    func testAttributed2() throws{
        let font = try XCTUnwrap(NSFont(name: "Helvetica", size: 12))
        var att=AttributedString(NSAttributedString(string: "Lorem ipsum dolor sit amet", attributes: [.font: font]))
        var attributes = AttributeContainer()
        attributes.appKit.backgroundColor = .blue
        att[try XCTUnwrap(att.range(of: "Lorem"))].mergeAttributes(attributes)
        try writeAndValidateDocX(attributedString: NSAttributedString(att))
        
    }
    
    @available(macOS 12, *)
    func testMarkdown()throws{
        let mD="~~This~~ is a **Markdown** *string*."
        let att=try AttributedString(markdown: mD)
        try writeAndValidateDocX(attributedString: NSAttributedString(att))
    }
    
    @available(macOS 12, *)
    func testMarkdown_linkNewline() throws {
        let mD =
"""
~~This~~ is a **Markdown** *string*.\\
And this is a [link](http://www.example.com).
"""
                             
        let att=try AttributedString(markdown: mD)
        try writeAndValidateDocX(attributedString: NSAttributedString(att))
    }
    
    @available(macOS 12, *)
    func testMarkdown_Image() throws {

        let url=try XCTUnwrap(bundle.url(forResource: "lenna", withExtension: "md"))

        let att=try AttributedString(contentsOf: url, baseURL: url.deletingLastPathComponent())
        let imageRange=try XCTUnwrap(att.range(of: "This is an image"))
        let imageURL=try XCTUnwrap(att[imageRange].imageURL)
        let imageURLInBundle=try XCTUnwrap(bundle.url(forResource: "lenna", withExtension:"png"))
        XCTAssertEqual(imageURL.absoluteString, imageURLInBundle.absoluteString)
        
        try writeAndValidateDocX(attributedString: NSAttributedString(att))
    }
    
    @available(macOS 12, *)
    func testMarkdown_mixed() throws {
        let mD =
"""
~~This~~ is a **Markdown** *string*.\\
And this is a [link](http://www.example.com).
"""
        
        var att=try AttributedString(markdown: mD)
        var attributes = AttributeContainer()
        attributes.appKit.foregroundColor = .red
        att[try XCTUnwrap(att.range(of: "This"))].mergeAttributes(attributes)
        try writeAndValidateDocX(attributedString: NSAttributedString(att))
    }
    
    @available(macOS 12, *)
    func testMarkdown_Emoji() throws {
        let mD =
"""
~~This~~ is a **Markdown** *string*.\\
And this is a [link](http://www.example.com).\\
These are flag **emoji** 🏳️‍🌈🇨🇦🇹🇩🇨🇳🇪🇹.
These are ~~emoji~~ faces 👶🏼👩🏾‍🦰👱🏻‍♀️👷🏿‍♀️💂🏼‍♀️👩🏽‍🚀.
"""
                             
        var att=try AttributedString(markdown: mD)
        var attributes = AttributeContainer()
        attributes.appKit.foregroundColor = .red
        att[try XCTUnwrap(att.range(of: "This"))].mergeAttributes(attributes)
        try writeAndValidateDocX(attributedString: NSAttributedString(att))
    }
    
    func testComposedHiragana() throws{
       // this string has some of the hiragana composed of two characters instead of one
let string = """
"From: 研究サービス noreply@qemailserver.com Subject: テクノロジーに関するご意見をお聞かせください\nDate: May 28, 2020 8:38\nTo:test\n   簡単なアンケート回答いただいた方に5ドル進 呈いたします。\n私たちはこの異例の困難な状況にあり、アンケートに回答していただくこと は、あなたにとって優先事項でないかもしれないことを理解しております。し かしながら、弊社にとってお客様の声は大変貴重であり、あなたのご意見をぜ\nひお聞かせいただきたいと考えております。\nこのアンケートにお答えいただきますと、 5ドルのAmazonギフトカード を進呈 いたします。ギフトカードは参加条件を満たし、アンケートすべてを完了して\nいただいたご参加者様にのみ贈らせていただきますのでご了承ください。\nこの機密扱いの調査はテクノロジー業界の大手企業であるクライアントに代わ り、Qualtricsアンケートプラットフォーム上で実施されます。この企業のサー ビスについてお伺いするものです。アンケートの所要時間は20~25分ほどで\nす。\n下記をクリックするか、ウェブブラウザにリンクをコピー・アンド・ペースト して回答を始めてください。\nクリック\nありがとうございます。ご協力に感謝いたします。\n本アンケートは任意でご参加いただくものです。条件を満たし、本アンケートを完了された ご参加者様へ、この招待状が送信されたメールアドレス宛にギフトカードが送信されます。\n処理には2~3週間を要しますのでご了承ください。当社は調査を実施することのみを目的 としてご連絡させていただきました。民族性など、基本的な人口統計情報をお尋ねする場合 があります。ご参加者様のデータは機密情報として保持され、テクノロジー業界の大手企業 である当社のクライアントと集計データとしてのみ共有されます。クライアントはこの情報 をサービスの調査の実施およびサービスの向上を目的として使用します。本アンケートを完\n "
"""
        
        let font = NSFont(name: "Hiragino Sans", size: 13)!
        let att = NSAttributedString(string: string, attributes: [.font: font])

        var options = DocXOptions()
        options.author = "Michael Knight"
        options.title = "Japanese Document"

        try writeAndValidateDocX(attributedString: att, options: options)
        
    }
    
    func testStyles() throws {
        // Create a title
        let text = NSMutableAttributedString(string: "Title", attributes:[.paragraphStyleId: "Title"])
        
        // Append a few new lines
        text.append(NSAttributedString(string: "\n\n\n"))
        
        // Append some interesting text
        let loremIpsum = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        text.append(NSAttributedString(string: loremIpsum))
        
        // Create a DocXStyleConfiguration that uses the test styles.xml file
        let stylesURL = try XCTUnwrap(bundle.url(forResource: "styles", withExtension: "xml"),"styles.cml not found")
           
        let config = try DocXStyleConfiguration(stylesXMLURL: stylesURL, outputFontFamily: false)
        
        // Create DocXOptions and add the style configuration
        var options = DocXOptions()
        options.styleConfiguration = config
        try writeAndValidateDocX(attributedString: text, options: options)
    }
    
    
    func testAvailableStyles() throws {
        
        let loremIpsum = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        
        let stylesURL = try XCTUnwrap(bundle.url(forResource: "styles", withExtension: "xml"),"styles.cml not found")
           
        let config = try DocXStyleConfiguration(stylesXMLURL: stylesURL, outputFontFamily: false)
        let paragraphStyles=try XCTUnwrap(config.availableParagraphStyles, "no styles found")
        let text=NSMutableAttributedString()
        for style in paragraphStyles{
            text.append(NSAttributedString(string: "\(style)\r", attributes:[.paragraphStyleId:style]))
            text.append(NSAttributedString(string: "\(loremIpsum)\r", attributes:[.paragraphStyleId:style]))
        }
        text.append(NSAttributedString(string: "\r", attributes: [.breakType:BreakType.page]))

        let characterStyles=try XCTUnwrap(config.availableCharacterStyles, "no styles found")

        for style in characterStyles{
            text.append(NSAttributedString(string: "\r\(style):\r", attributes:[.characterStyleId:style]))
            text.append(NSAttributedString(string: loremIpsum, attributes: [.characterStyleId:style]))
        }
        
        // Create DocXOptions and add the style configuration
        var options = DocXOptions()
        options.styleConfiguration = config
        try writeAndValidateDocX(attributedString: text, options: options)
    }
    
    
    func testFontErasure() throws{
        let loremIpsum = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        let text=NSMutableAttributedString()
        let fonts=[NSFont.boldSystemFont(ofSize: 12),
                   NSFont.systemFont(ofSize: 19, weight: .light),
                   NSFont(descriptor: NSFontDescriptor().withSymbolicTraits(.italic), size: 15)]
            .compactMap({$0})
        
        for font in fonts{
            text.append(NSAttributedString(string: loremIpsum, attributes: [.font:font]))
            text.append(NSAttributedString(string: "\r\r", attributes: [.font:font]))
        }
        
        var options=DocXOptions()
        options.styleConfiguration=DocXStyleConfiguration(stylesXMLDocument: nil, outputFontFamily: false)
        
        try writeAndValidateDocX(attributedString: text, options: options)

        try writeAndValidateDocX(attributedString: text)
    }
    
    
    func testStylesFomString() throws{
        
        let loremIpsum = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        
        let stylesString="""
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml" xmlns:w16cex="http://schemas.microsoft.com/office/word/2018/wordml/cex" xmlns:w16cid="http://schemas.microsoft.com/office/word/2016/wordml/cid" xmlns:w16="http://schemas.microsoft.com/office/word/2018/wordml" xmlns:w16sdtdh="http://schemas.microsoft.com/office/word/2020/wordml/sdtdatahash" xmlns:w16se="http://schemas.microsoft.com/office/word/2015/wordml/symex" mc:Ignorable="w14 w15 w16se w16cid w16 w16cex w16sdtdh"><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:link w:val="Heading1Char"/><w:uiPriority w:val="9"/><w:qFormat/><w:rsid w:val="002B4C58"/><w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="240"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:rFonts w:asciiTheme="majorHAnsi" w:eastAsiaTheme="majorEastAsia" w:hAnsiTheme="majorHAnsi" w:cstheme="majorBidi"/><w:color w:val="2F5496" w:themeColor="accent1" w:themeShade="BF"/><w:sz w:val="32"/><w:szCs w:val="32"/></w:rPr></w:style><w:style w:type="character" w:default="1" w:styleId="DefaultParagraphFont"><w:name w:val="Default Paragraph Font"/><w:uiPriority w:val="1"/><w:semiHidden/><w:unhideWhenUsed/></w:style><w:style w:type="table" w:default="1" w:styleId="TableNormal"><w:name w:val="Normal Table"/><w:uiPriority w:val="99"/><w:semiHidden/><w:unhideWhenUsed/><w:tblPr><w:tblInd w:w="0" w:type="dxa"/><w:tblCellMar><w:top w:w="0" w:type="dxa"/><w:left w:w="108" w:type="dxa"/><w:bottom w:w="0" w:type="dxa"/><w:right w:w="108" w:type="dxa"/></w:tblCellMar></w:tblPr></w:style><w:style w:type="numbering" w:default="1" w:styleId="NoList"><w:name w:val="No List"/><w:uiPriority w:val="99"/><w:semiHidden/><w:unhideWhenUsed/></w:style><w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:link w:val="TitleChar"/><w:uiPriority w:val="10"/><w:qFormat/><w:rsid w:val="002B4C58"/><w:pPr><w:contextualSpacing/></w:pPr><w:rPr><w:rFonts w:asciiTheme="majorHAnsi" w:eastAsiaTheme="majorEastAsia" w:hAnsiTheme="majorHAnsi" w:cstheme="majorBidi"/><w:spacing w:val="-10"/><w:kern w:val="28"/><w:sz w:val="56"/><w:szCs w:val="56"/></w:rPr></w:style><w:style w:type="character" w:customStyle="1" w:styleId="TitleChar"><w:name w:val="Title Char"/><w:basedOn w:val="DefaultParagraphFont"/><w:link w:val="Title"/><w:uiPriority w:val="10"/><w:rsid w:val="002B4C58"/><w:rPr><w:rFonts w:asciiTheme="majorHAnsi" w:eastAsiaTheme="majorEastAsia" w:hAnsiTheme="majorHAnsi" w:cstheme="majorBidi"/><w:spacing w:val="-10"/><w:kern w:val="28"/><w:sz w:val="56"/><w:szCs w:val="56"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:link w:val="SubtitleChar"/><w:uiPriority w:val="11"/><w:qFormat/><w:rsid w:val="002B4C58"/><w:pPr><w:numPr><w:ilvl w:val="1"/></w:numPr><w:spacing w:after="160"/></w:pPr><w:rPr><w:color w:val="5A5A5A" w:themeColor="text1" w:themeTint="A5"/><w:spacing w:val="15"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:style><w:style w:type="character" w:customStyle="1" w:styleId="SubtitleChar"><w:name w:val="Subtitle Char"/><w:basedOn w:val="DefaultParagraphFont"/><w:link w:val="Subtitle"/><w:uiPriority w:val="11"/><w:rsid w:val="002B4C58"/><w:rPr><w:color w:val="5A5A5A" w:themeColor="text1" w:themeTint="A5"/><w:spacing w:val="15"/><w:sz w:val="22"/><w:szCs w:val="22"/></w:rPr></w:style><w:style w:type="character" w:customStyle="1" w:styleId="Heading1Char"><w:name w:val="Heading 1 Char"/><w:basedOn w:val="DefaultParagraphFont"/><w:link w:val="Heading1"/><w:uiPriority w:val="9"/><w:rsid w:val="002B4C58"/><w:rPr><w:rFonts w:asciiTheme="majorHAnsi" w:eastAsiaTheme="majorEastAsia" w:hAnsiTheme="majorHAnsi" w:cstheme="majorBidi"/><w:color w:val="2F5496" w:themeColor="accent1" w:themeShade="BF"/><w:sz w:val="32"/><w:szCs w:val="32"/></w:rPr></w:style></w:styles>
"""
        let config=try DocXStyleConfiguration(stylesXMLString: stylesString, outputFontFamily: false)
        let characterStyles = try XCTUnwrap(config.availableCharacterStyles)
        XCTAssertFalse(characterStyles.isEmpty)
        
        let paragraphStyles = try XCTUnwrap(config.availableParagraphStyles)
        XCTAssertFalse(paragraphStyles.isEmpty)
        
        let text=NSMutableAttributedString()
        for style in paragraphStyles{
            text.append(NSAttributedString(string: "\(style)\r", attributes:[.paragraphStyleId:style]))
            text.append(NSAttributedString(string: "\(loremIpsum)\r", attributes:[.paragraphStyleId:style]))
        }
        text.append(NSAttributedString(string: "\r", attributes: [.breakType:BreakType.page]))


        for style in characterStyles{
            text.append(NSAttributedString(string: "\r\(style):\r", attributes:[.characterStyleId:style]))
            text.append(NSAttributedString(string: loremIpsum, attributes: [.characterStyleId:style]))
        }
        
        // Create DocXOptions and add the style configuration
        var options = DocXOptions()
        options.styleConfiguration = config
        try writeAndValidateDocX(attributedString: text, options: options)
        
    }
    
    func testMinimumStyle() throws{
        
        let loremIpsum = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        
        let stylesString="""
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml" xmlns:w16cex="http://schemas.microsoft.com/office/word/2018/wordml/cex" xmlns:w16cid="http://schemas.microsoft.com/office/word/2016/wordml/cid" xmlns:w16="http://schemas.microsoft.com/office/word/2018/wordml" xmlns:w16sdtdh="http://schemas.microsoft.com/office/word/2020/wordml/sdtdatahash" xmlns:w16se="http://schemas.microsoft.com/office/word/2015/wordml/symex" mc:Ignorable="w14 w15 w16se w16cid w16 w16cex w16sdtdh"><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style></w:styles>
"""
        let config=try DocXStyleConfiguration(stylesXMLString: stylesString, outputFontFamily: false)

        let paragraphStyles = try XCTUnwrap(config.availableParagraphStyles)
        XCTAssertFalse(paragraphStyles.isEmpty)
        
        let text=NSMutableAttributedString()
        for style in paragraphStyles{
            text.append(NSAttributedString(string: "\(style)\r", attributes:[.paragraphStyleId:style]))
            text.append(NSAttributedString(string: "\(loremIpsum)\r", attributes:[.paragraphStyleId:style]))
        }
        text.append(NSAttributedString(string: "\r", attributes: [.breakType:BreakType.page]))

        var options = DocXOptions()
        options.styleConfiguration = config
        try writeAndValidateDocX(attributedString: text, options: options)
        
    }
    
    func testPageSize() throws{
        let loremIpsum = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        
        func makeText(howMany:Int)->NSMutableAttributedString{
            let text=NSMutableAttributedString()
            
            for _ in 0...howMany{
                text.append(NSAttributedString(string: loremIpsum))
                text.append(NSAttributedString(string: "\r\r"))
            }
            return text
        }
        
        
        let defs = [PageDefinition(pageSize: .A4),
                    PageDefinition(pageSize: .letter),
                    PageDefinition(pageSize: .A4, pageMargins: .init(edgeInsets: NSEdgeInsets(top: 500, left: 100, bottom: 50, right: 40))),
                    PageDefinition(pageSize: .init(width: Measurement(value: 10, unit: .centimeters), height: Measurement(value: 10, unit: .centimeters))),
                    PageDefinition(pageSize: .init(width: Measurement(value: 10, unit: .inches), height: Measurement(value: 10, unit: .centimeters)), pageMargins: PageDefinition.PageMargins(top: Measurement(value: 1, unit: .centimeters), bottom: Measurement(value: 25, unit: .millimeters), left: .init(value: 1, unit: .inches), right: .init(value: 50, unit: .points))),
                    PageDefinition(pageSize: .init(width: .init(value: 30, unit: .centimeters), height: .init(value: 20, unit: .centimeters)), pageMargins: .init(top: .init(value: 1, unit: .centimeters), bottom: .init(value: 1, unit: .centimeters), left: .init(value: 1, unit: .centimeters), right: .init(value: 1, unit: .centimeters)))]
        
        for def in defs{
            var options=DocXOptions()
            options.pageDefinition=def
            
            let text=makeText(howMany: 20)
            text.insert(NSAttributedString(string: "\(def.description)\r\r", attributes: [.foregroundColor: NSColor.red]), at: 0)
            try writeAndValidateDocX(attributedString: text, options: options)
        }
        
        
    }
    
    
    func testScaleImageToSize() throws{
        let loremIpsum = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
        
        let imageURL=try XCTUnwrap(bundle.url(forResource: "lenna", withExtension: "png"), "ImageURL not found")
        let imageData=try XCTUnwrap(Data(contentsOf: imageURL), "Image not found")
        let attachement=NSTextAttachment(data: imageData, ofType: kUTTypePNG as String)
        
        let text=NSMutableAttributedString()
        text.append(NSAttributedString(string: loremIpsum, attributes: [.foregroundColor: NSColor.red]))
        text.append(NSAttributedString(string: "\r"))
        text.append(NSAttributedString(attachment: attachement))
        text.append(NSAttributedString(string: loremIpsum, attributes: [.foregroundColor: NSColor.black, .font: NSFont(name: "Helvetica", size: 19)!]))
        
        let defs = [PageDefinition(pageSize: .A4)]
        
        for def in defs{
            var options=DocXOptions()
            options.pageDefinition=def
            try writeAndValidateDocX(attributedString: text, options: options)
        }
        
    }
    
    func testLists() throws {
        let string = """
List 1 Level 0
List 1 Level 1
Some text
List 2 Level 0
List 2 Level 1
Some more text
List 3 Level 0
"""
        let attributedString = NSMutableAttributedString(string: string)
        let nsString = string as NSString

        // Build NSTextList objects for two separate lists with nested levels
        //
        let list1Level0 = NSTextList(markerFormat: .decimal, options: 0)
        let list1Level1 = NSTextList(markerFormat: .disc, options: 0)
        
        let list2Level0 = NSTextList(markerFormat: .lowercaseLatin, options: 0)
        let list2Level1 = NSTextList(markerFormat: .uppercaseRoman, options: 0)
        
        // Create a third list and set its `startingItemNumber` to 2, to indicate
        // that it continues from the first list
        let list3Level0 = NSTextList(markerFormat: .decimal, options: 0)
        list3Level0.startingItemNumber = 2

        let paragraphDefinitions: [(text: String, textLists: [NSTextList], expectedStyle: DocXListStyle, expectedLevel: Int)] = [
            ("List 1 Level 0", [list1Level0], .decimal, 0),
            ("List 1 Level 1", [list1Level0, list1Level1], .bullet, 1),
            ("List 2 Level 0", [list2Level0], .lowerLetter, 0),
            ("List 2 Level 1", [list2Level0, list2Level1], .upperRoman, 1),
            ("List 3 Level 0", [list3Level0], .decimal, 0),
        ]

        for definition in paragraphDefinitions {
            let range = nsString.range(of: definition.text)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.textLists = definition.textLists
            attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        }

        let paragraphRanges = attributedString.paragraphRanges
        XCTAssertEqual(paragraphRanges.count, 7)

        // Map only the list paragraphs (skip the non-list text at indices 2 and 5)
        let listParagraphIndices = [0, 1, 3, 4, 6]
        for (defIndex, paraIndex) in listParagraphIndices.enumerated() {
            let definition = paragraphDefinitions[defIndex]
            XCTAssertNotNil(paragraphRanges[paraIndex].numberingId)
            XCTAssertEqual(paragraphRanges[paraIndex].numberingLevel, definition.expectedLevel)
            XCTAssertEqual(paragraphRanges[paraIndex].listStyle, definition.expectedStyle)
            XCTAssertNotNil(paragraphRanges[paraIndex].numberingElement)
        }

        // The first two lists should have different numbering IDs
        XCTAssertNotEqual(paragraphRanges[0].numberingId, paragraphRanges[3].numberingId)
        
        // The first and third lists should shared the same ID
        XCTAssertEqual(paragraphRanges[0].numberingId, paragraphRanges[6].numberingId)

        var numberingConfig = DocXNumberingConfiguration()
        for (defIndex, paraIndex) in listParagraphIndices.enumerated() {
            if let numId = paragraphRanges[paraIndex].numberingId,
               let style = paragraphRanges[paraIndex].listStyle {
                numberingConfig.register(numId: numId, style: style, level: paragraphDefinitions[defIndex].expectedLevel)
            }
        }
        
        // This isn't a great check, but at least make sure that some of the XML
        // appears correct
        let xml = numberingConfig.numberingXML()
        XCTAssertTrue(xml.contains("w:numbering"))
        XCTAssertTrue(xml.contains("w:val=\"decimal\""))
        XCTAssertTrue(xml.contains("w:val=\"bullet\""))
        XCTAssertTrue(xml.contains("w:val=\"lowerLetter\""))
        XCTAssertTrue(xml.contains("w:val=\"upperRoman\""))

        try writeAndValidateDocX(attributedString: attributedString)
    }

    func testFootnotes() throws {
        let string = "Body text note one and note two\rFirst footnote body\rSecond footnote body"
        let attributedString = NSMutableAttributedString(string: string)
        let nsString = string as NSString
        attributedString.addAttribute(.footnoteReferenceId,
                                      value: 1,
                                      range: nsString.range(of: "note one"))
        attributedString.addAttribute(.footnoteReferenceId,
                                      value: 2,
                                      range: nsString.range(of: "note two"))
        attributedString.addAttribute(.footnoteBodyId,
                                      value: 1,
                                      range: nsString.range(of: "First footnote body"))
        attributedString.addAttribute(.footnoteBodyId,
                                      value: 2,
                                      range: nsString.range(of: "Second footnote body"))

        let noteConfig = DocXNoteConfiguration(attributedString: attributedString)
        XCTAssertTrue(noteConfig.hasFootnotes)
        let xml = noteConfig.notesXML(for: .footnote, linkRelations: [], options: DocXOptions())
        XCTAssertTrue(xml.contains("w:footnotes"))
        XCTAssertTrue(xml.contains("w:id=\"1\""))
        XCTAssertTrue(xml.contains("w:id=\"2\""))
        XCTAssertTrue(xml.contains("w:footnoteRef"))

        try writeAndValidateDocX(attributedString: attributedString)
    }

    func testEndnotes() throws {
        let string = "Body text note one and note two\rFirst endnote body\rSecond endnote body"
        let attributedString = NSMutableAttributedString(string: string)
        let nsString = string as NSString
        attributedString.addAttribute(.endnoteReferenceId,
                                      value: 1,
                                      range: nsString.range(of: "note one"))
        attributedString.addAttribute(.endnoteReferenceId,
                                      value: 2,
                                      range: nsString.range(of: "note two"))
        attributedString.addAttribute(.endnoteBodyId,
                                      value: 1,
                                      range: nsString.range(of: "First endnote body"))
        attributedString.addAttribute(.endnoteBodyId,
                                      value: 2,
                                      range: nsString.range(of: "Second endnote body"))

        let noteConfig = DocXNoteConfiguration(attributedString: attributedString)
        XCTAssertTrue(noteConfig.hasEndnotes)
        let xml = noteConfig.notesXML(for: .endnote, linkRelations: [], options: DocXOptions())
        XCTAssertTrue(xml.contains("w:endnotes"))
        XCTAssertTrue(xml.contains("w:id=\"1\""))
        XCTAssertTrue(xml.contains("w:id=\"2\""))
        XCTAssertTrue(xml.contains("w:endnoteRef"))

        try writeAndValidateDocX(attributedString: attributedString)
    }

    func testWriteSections() throws {
        let section1 = NSMutableAttributedString(string: "Section 1 note\rSection 1 footnote body")
        let section1String = section1.string as NSString
        section1.addAttribute(.footnoteReferenceId,
                              value: 1,
                              range: section1String.range(of: "note"))
        section1.addAttribute(.footnoteBodyId,
                              value: 1,
                              range: section1String.range(of: "Section 1 footnote body"))

        let section2 = NSMutableAttributedString(string: "Section 2 note\rSection 2 footnote body")
        let section2String = section2.string as NSString
        section2.addAttribute(.footnoteReferenceId,
                              value: 2,
                              range: section2String.range(of: "note"))
        section2.addAttribute(.footnoteBodyId,
                              value: 2,
                              range: section2String.range(of: "Section 2 footnote body"))

        let sections = [section1 as NSAttributedString, section2 as NSAttributedString]
        var options = DocXOptions()
        options.footnoteNumberRestart = .eachSection

        let xml = try sections[0].docXDocument(sectionStrings: sections, options: options)
        XCTAssertTrue(xml.contains("w:type w:val=\"nextPage\""))
        
        // `components(separatedBy:) - 1` gives the number of times each XML marker appears
        XCTAssertEqual(xml.components(separatedBy: "<w:sectPr").count - 1, 2)
        XCTAssertEqual(xml.components(separatedBy: "<w:footnotePr>").count - 1, 2)
        XCTAssertEqual(xml.components(separatedBy: "w:numRestart w:val=\"eachSect\"").count - 1, 2)

        try writeAndValidateSections(sections, options: options)
    }

    func testWriteSections_duplicateFootnoteIdThrows() throws {
        let section1 = NSMutableAttributedString(string: "Section 1 note\rSection 1 footnote body")
        let section1String = section1.string as NSString
        section1.addAttribute(.footnoteReferenceId, value: 1, range: section1String.range(of: "note"))
        section1.addAttribute(.footnoteBodyId, value: 1, range: section1String.range(of: "Section 1 footnote body"))

        let section2 = NSMutableAttributedString(string: "Section 2 note\rSection 2 footnote body")
        let section2String = section2.string as NSString
        section2.addAttribute(.footnoteReferenceId, value: 1, range: section2String.range(of: "note"))
        section2.addAttribute(.footnoteBodyId, value: 1, range: section2String.range(of: "Section 2 footnote body"))

        let sections = [section1 as NSAttributedString, section2 as NSAttributedString]
        var options = DocXOptions()
        options.footnoteNumberRestart = .eachSection

        let url = self.tempURL.appendingPathComponent("duplicate-ids").appendingPathExtension("docx")
        XCTAssertThrowsError(try DocXWriter.write(sections: sections, to: url, options: options)) { error in
            guard case DocXSavingErrors.duplicateNoteId(let kind, let id) = error else {
                XCTFail("Expected duplicateNoteId error, got \(error)")
                return
            }
            XCTAssertEqual(kind, "footnote")
            XCTAssertEqual(id, 1)
        }
    }

    // MARK: Performance Tests
    
    func testPerformanceLongBook() {
        // Two paragraphs / 100 words
        let twoParagraphs =
"""
This property contains the space (measured in points) added at the end of the paragraph to separate it from the following paragraph. This value is always nonnegative. The space between paragraphs is determined by adding the previous paragraph’s paragraphSpacing and the current paragraph’s paragraphSpacingBefore.
Specifies the border displayed above a set of paragraphs which have the same set of paragraph border settings. Note that if the adjoining paragraph has identical border settings and a between border is specified, a single between border will be used instead of the bottom border for the first and a top border for the second.
"""
        // Create a "book" that consists of 400 chapters each with 5,000 words
        // (2 million words total)
        let chapterString = String(repeating: twoParagraphs, count: 50)
        let chapterAttributedString = NSAttributedString(string: chapterString)
        let chapters = Array(repeating: chapterAttributedString, count: 400)
        
        let basename = docxBasename(attributedString:chapterAttributedString)
        let url = self.tempURL.appendingPathComponent(basename).appendingPathExtension("docx")
        
        measure {
            try? DocXWriter.write(pages: chapters, to: url)
        }
    }
    
    func testPerformanceLongString() throws {
        // Two paragraphs / 100 words
        let twoParagraphs =
"""
This property contains the space (measured in points) added at the end of the paragraph to separate it from the following paragraph. This value is always nonnegative. The space between paragraphs is determined by adding the previous paragraph’s paragraphSpacing and the current paragraph’s paragraphSpacingBefore.
Specifies the border displayed above a set of paragraphs which have the same set of paragraph border settings. Note that if the adjoining paragraph has identical border settings and a between border is specified, a single between border will be used instead of the bottom border for the first and a top border for the second.
"""
        // Create a string that consists of 40,000 paragraphs
        // (2 million words total)
        let longString = String(repeating: twoParagraphs, count: 20_000)
        let longAttributedString = NSAttributedString(string: longString)
        
        let basename = docxBasename(attributedString:longAttributedString)
        let url = self.tempURL.appendingPathComponent(basename).appendingPathExtension("docx")
        measure {
            try? longAttributedString.writeDocX(to: url)
        }
    }
    
    func testSubscript_Superscript() throws {
        let string=NSMutableAttributedString(attributedString: NSAttributedString(string: "H"))
        string.append(NSAttributedString(string: "2", attributes: [.baselineOffset:-1, .foregroundColor:NSColor.blue]))
        string.append(NSAttributedString(string: "O", attributes: [.baselineOffset:0]))
        string.append(NSAttributedString(string: "2", attributes: [.baselineOffset:-1]))
        string.append(NSAttributedString(string: "\r\r"))
        let font=NSFont(name: "Courier", size: 15)!
        string.append(NSAttributedString(string: "E=m•c", attributes: [.font:font]))
        string.append(NSAttributedString(string: "2", attributes: [.font:font, .baselineOffset:1]))
        
        try writeAndValidateDocX(attributedString: string)
    }
    
    
    @available(macOS 11.0, *)
    func testImageWriting() throws{
        let types:[UTType] = [.png, .jpeg, .tiff, .pdf]
        let generator=ImageGenerator(size: CGSize(width: 200, height: 200))
        let imageURLs=try types.map({try generator.generateImage(type: $0)})
        let wrappers=try imageURLs.map({try FileWrapper(url: $0)})
        // make an `NSTextAttachement` for each supported type.
        var attachements=wrappers.map({NSTextAttachment(fileWrapper: $0)})
        
        let data=wrappers.last!.regularFileContents!
        let typeErased=NSTextAttachment(data: data, ofType: nil)
        attachements.append(typeErased)
        
        let loremIpsum = """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        
        """
        let loremAtt=NSAttributedString(string: loremIpsum)
        let newLine=NSAttributedString(string: "\r")
        
        let att=NSMutableAttributedString()
        for attachement in attachements {
            att.append(loremAtt)
            let imageAtt=NSAttributedString(attachment: attachement)
            att.append(imageAtt)
            att.append(newLine)
        }
        
        try writeAndValidateDocX(attributedString: att)

        
    }
}

#endif
