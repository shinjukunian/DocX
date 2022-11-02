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

class DocXTests: XCTestCase {

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
            XCTFail()
            return
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
    
    func testLink() throws {
        let string="楽天 https://www.rakuten-sec.co.jp/"
        let attributed=NSMutableAttributedString(string: string)
        attributed.addAttributes([.font:NSFont.systemFont(ofSize: NSFont.systemFontSize)], range: NSRange(location: 0, length: attributed.length))
        let furigana="らくてん"
        let furiganaAnnotation=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, furigana as CFString, [kCTRubyAnnotationSizeFactorAttributeName:0.5] as CFDictionary)
        attributed.addAttribute(.ruby, value: furiganaAnnotation, range: NSRange(location: 0, length: 2))
        attributed.addAttribute(.link, value: URL(string: "https://www.rakuten-sec.co.jp/")!, range: NSRange(location: 3, length: 30))
        try writeAndValidateDocX(attributedString: attributed)
        
        sleep(1)
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
        let attachement=NSTextAttachment(data: imageData, ofType: kUTTypePNG as String)
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
        let attachement=NSTextAttachment(data: imageData, ofType: kUTTypePNG as String)
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
        let attachement=NSTextAttachment(data: imageData, ofType: kUTTypePNG as String)
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
        let attachement=NSTextAttachment(data: imageData, ofType: kUTTypePNG as String)
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
        let imageURL=URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("lenna.png")
        let imageData=try XCTUnwrap(Data(contentsOf: imageURL), "Image not found")
        let attachement=NSTextAttachment(data: imageData, ofType: kUTTypePNG as String)
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
        var att=AttributedString("Lorem ipsum dolor sit amet")
        att.strokeColor = .green
        att.strokeWidth = -2
        att.font = NSFont(name: "Helvetica", size: 12)
        att.foregroundColor = .gray
        
        try writeAndValidateDocX(attributedString: NSAttributedString(att))
    }
    
    
    @available(macOS 12, *)
    func testAttributed2() throws{
        var att=AttributedString("Lorem ipsum dolor sit amet")
        att.font = NSFont(name: "Helvetica", size: 12)
        att[att.range(of: "Lorem")!].backgroundColor = .blue
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
        
#if SWIFT_PACKAGE
        let bundle=Bundle.module
#else
        let bundle=Bundle(for: DocXTests.self)
#endif
        
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
        att[att.range(of: "This")!].foregroundColor = .red
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
        att[att.range(of: "This")!].foregroundColor = .red
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
}

#endif

