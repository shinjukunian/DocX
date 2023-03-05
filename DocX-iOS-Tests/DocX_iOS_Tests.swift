//
//  DocX_iOS_Tests.swift
//  DocX-iOS-Tests
//
//  Created by Morten Bertz on 2019/03/11.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

#if os(iOS)
import MobileCoreServices
import XCTest

#if(canImport(UniformTypeIdentifiers))
import UniformTypeIdentifiers
#endif

@testable import DocX

#if SWIFT_PACKAGE
import DocXTestsCommon
#endif

@available(iOS 10.0, *)
class DocX_iOS_Tests: XCTestCase, DocXTesting {
    
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
    
    func testWriteXML(){
        let string=""
        let attributedString=NSAttributedString(string: string)
        do{
            let xml=try attributedString.docXDocument()
            let url=self.tempURL.appendingPathComponent("testXML").appendingPathExtension("xml")
            try xml.write(to: url, atomically: true, encoding: .utf8)
            
        }
        catch let error{
            XCTFail(error.localizedDescription)
        }
    }
    
    
    
    func testBlank() throws{
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
        let attributed=NSAttributedString(string: string, attributes: [.font:UIFont.systemFont(ofSize: UIFont.systemFontSize)])
        try writeAndValidateDocX(attributedString: attributed)
    }
    
    func test山田FuriganaAttributed() throws{
        let string="山田"
        let furigana="やまだ"
        let ruby=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, furigana as CFString, [kCTRubyAnnotationSizeFactorAttributeName:0.5] as CFDictionary)
        let rubyKey=NSAttributedString.Key(kCTRubyAnnotationAttributeName as String)
        let attributed=NSAttributedString(string: string, attributes: [.font:UIFont.systemFont(ofSize: UIFont.systemFontSize), rubyKey:ruby])
        try writeAndValidateDocX(attributedString: attributed)
    }
    
    
    var yamadaDenkiString:NSMutableAttributedString{
        let string="山田電気"
        let furigana="やまだ"
        let sizeFactorDictionary=[kCTRubyAnnotationSizeFactorAttributeName:0.5] as CFDictionary
        let yamadaRuby=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, furigana as CFString, sizeFactorDictionary)
        
        let rubyKey=NSAttributedString.Key(kCTRubyAnnotationAttributeName as String)
        let attributedString=NSMutableAttributedString(string: string, attributes: [.font:UIFont.systemFont(ofSize: UIFont.systemFontSize), .foregroundColor:UIColor.red])
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
    
    func test山田電気FuriganaAttributed_ParagraphStyle_italic() throws {
        let attributed=yamadaDenkiString
        let style=NSParagraphStyle.default
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let boldFont=UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)
        attributed.addAttribute(.font, value: boldFont, range: NSRange(location: 0, length: 2))
        try writeAndValidateDocX(attributedString: attributed)

    }
    
    func testLink() throws{
        let string="楽天 https://www.rakuten-sec.co.jp/"
        let attributed=NSMutableAttributedString(string: string)
        attributed.addAttributes([.font:NSFont.systemFont(ofSize: NSFont.systemFontSize)], range: NSRange(location: 0, length: attributed.length))
        let furigana="らくてん"
        let furiganaAnnotation=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, furigana as CFString, [kCTRubyAnnotationSizeFactorAttributeName:0.5] as CFDictionary)
        attributed.addAttribute(.ruby, value: furiganaAnnotation, range: NSRange(location: 0, length: 2))
        attributed.addAttribute(.link, value: URL(string: "https://www.rakuten-sec.co.jp/")!, range: NSRange(location: 3, length: 30))
        try writeAndValidateDocX(attributedString: attributed)
        
    }

    func test山田電気FuriganaAttributed_ParagraphStyle_underline() throws {
        let attributed=yamadaDenkiString
        //        let style=NSParagraphStyle.default
        //        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let underlineStyle:NSUnderlineStyle = [.single,.byWord]
        attributed.addAttribute(.underlineStyle, value: underlineStyle.rawValue, range:NSRange(location: 0, length: attributed.length))
        try writeAndValidateDocX(attributedString: attributed)
    }
    
    func test山田電気FuriganaAttributed_ParagraphStyle_strikethrough() throws {
        let attributed=yamadaDenkiString
        //        let style=NSParagraphStyle.default
        //        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let underlineStyle:NSUnderlineStyle = [.single]
        attributed.addAttribute(.strikethroughStyle, value: underlineStyle.rawValue, range:NSRange(location: 0, length: attributed.length))
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
    
    func testMultipage() throws{
        let longString = """
            1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            2. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            3. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            4. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            5. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            """
        let attributed=NSAttributedString(string: longString, attributes: [.font:NSFont.systemFont(ofSize: 20)])
        try writeAndValidateDocX(attributedString: attributed)

    }
    


    func testImage() throws{
        let longString = """
            1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """

        let imageURL=try XCTUnwrap(bundle.url(forResource: "Picture1", withExtension: "png"))
        let imageData=try XCTUnwrap(Data(contentsOf: imageURL), "Image not found")
        let attachement=NSTextAttachment(data: imageData, ofType: kUTTypePNG as String)
        let attributed=NSAttributedString(string: longString, attributes: [.foregroundColor: NSColor.green])
        let imageString=NSAttributedString(attachment: attachement)
        let result=NSMutableAttributedString()
        result.append(attributed)
        result.append(imageString)
        try writeAndValidateDocX(attributedString: result)
    }

    
    @available(iOS 15, *)
    func testAttributed(){
        var att=AttributedString("Lorem ipsum dolor sit amet")
        att.strokeColor = .green
        att.strokeWidth = -2
        att.font = UIFont(name: "Helvetica", size: 12)
        att.foregroundColor = .gray

        do{
            let attributed = NSAttributedString(att)
            try writeAndValidateDocX(attributedString: attributed)
        }
        catch let error{
            XCTFail(error.localizedDescription)
        }
        
    }
    
    @available(iOS 15, *)
    func testMarkdown()throws{
        let mD="~~This~~ is a **Markdown** *string*."
        let att=try AttributedString(markdown: mD)
        let url=self.tempURL.appendingPathComponent(UUID().uuidString + "_myDocument_\("Markdown")").appendingPathExtension("docx")
        try att.writeDocX(to: url)
    }
    
    @available(iOS 15, *)
    func testMarkdown_link()throws{
        let mD =
"""
~~This~~ is a **Markdown** *string*.\\
And this is a [link](http://www.example.com).
"""
                             
        let att=try AttributedString(markdown: mD)
        let url=self.tempURL.appendingPathComponent(UUID().uuidString + "_myDocument_\("Markdown")").appendingPathExtension("docx")
        try att.writeDocX(to: url)
    }
    
    @available(iOS 15, *)
    func testMarkdown_Image()throws{
                
        let url=try XCTUnwrap(bundle.url(forResource: "lenna", withExtension: "md"))

        let att=try AttributedString(contentsOf: url, baseURL: url.deletingLastPathComponent())
        let imageRange=try XCTUnwrap(att.range(of: "This is an image"))
        let imageURL=try XCTUnwrap(att[imageRange].imageURL)
        let imageURLInBundle=try XCTUnwrap(bundle.url(forResource: "lenna", withExtension:"png"))
        XCTAssertEqual(imageURL.absoluteString, imageURLInBundle.absoluteString)
        let temp=self.tempURL.appendingPathComponent(UUID().uuidString + "_myDocument_\("Markdown_image")").appendingPathExtension("docx")
        try att.writeDocX(to: temp)
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
    
    @available(iOS 16.0, *)
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
