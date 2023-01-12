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
@testable import DocX

@available(iOS 10.0, *)
class DocX_iOS_Tests: XCTestCase {

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
    
    
    
    func testWriteDocX(attributedString:NSAttributedString){
        
        do{
            let url=self.tempURL.appendingPathComponent(UUID().uuidString + "_myDocument_\(attributedString.string.prefix(10))").appendingPathExtension("docx")
            try attributedString.writeDocX(to: url)
//            var readAttributes:NSDictionary?=nil
//            let docXString=try NSAttributedString(url: url, options: [:], documentAttributes: &readAttributes)
//            guard let attributes=readAttributes as? [String:Any] else{
//                XCTFail()
//                return
//            }
//            XCTAssertEqual(attributes[NSAttributedString.DocumentAttributeKey.documentType.rawValue] as! String, NSAttributedString.DocumentType.officeOpenXML.rawValue)
//            let string=docXString.string
//            print(string)
//            XCTAssertEqual(docXString.string, string)
            
        }
        catch let error{
            XCTFail(error.localizedDescription)
        }
    }
    
    
    func testBlank(){
        let string=""
        let attributedString=NSAttributedString(string: string)
        
        testWriteDocX(attributedString: attributedString)
    }
    
    func test山田Plain() {
        let string="山田"
        testWriteDocX(attributedString: NSAttributedString(string: string))
    }
    
    func test山田Attributed() {
        let string="山田"
        let attributed=NSAttributedString(string: string, attributes: [.font:UIFont.systemFont(ofSize: UIFont.systemFontSize)])
        testWriteDocX(attributedString: attributed)
    }
    
    func test山田FuriganaAttributed() {
        let string="山田"
        let furigana="やまだ"
        let ruby=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, furigana as CFString, [kCTRubyAnnotationSizeFactorAttributeName:0.5] as CFDictionary)
        let rubyKey=NSAttributedString.Key(kCTRubyAnnotationAttributeName as String)
        let attributed=NSAttributedString(string: string, attributes: [.font:UIFont.systemFont(ofSize: UIFont.systemFontSize), rubyKey:ruby])
        testWriteDocX(attributedString: attributed)
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
    
    func test山田電気FuriganaAttributed() {
        testWriteDocX(attributedString: yamadaDenkiString)
    }
    
    func test山田電気FuriganaAttributed_ParagraphStyle() {
        let attributed=yamadaDenkiString
        let style=NSParagraphStyle.default
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        testWriteDocX(attributedString: attributed)
        
    }
    
    func test山田電気FuriganaAttributed_ParagraphStyle_vertical() {
        let attributed=yamadaDenkiString
        let style=NSParagraphStyle.default
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        attributed.addAttribute(.verticalForms, value: true, range:NSRange(location: 0, length: attributed.length))
        testWriteDocX(attributedString: attributed)
    }
    
    func test山田電気FuriganaAttributed_ParagraphStyle_italic() {
        let attributed=yamadaDenkiString
        let style=NSParagraphStyle.default
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let boldFont=UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)
        attributed.addAttribute(.font, value: boldFont, range: NSRange(location: 0, length: 2))
        testWriteDocX(attributedString: attributed)
        
    }
    
    func testLink(){
        let string="楽天 https://www.rakuten-sec.co.jp/"
        let attributed=NSMutableAttributedString(string: string)
        attributed.addAttributes([.font:NSFont.systemFont(ofSize: NSFont.systemFontSize)], range: NSRange(location: 0, length: attributed.length))
        let furigana="らくてん"
        let furiganaAnnotation=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, furigana as CFString, [kCTRubyAnnotationSizeFactorAttributeName:0.5] as CFDictionary)
        attributed.addAttribute(.ruby, value: furiganaAnnotation, range: NSRange(location: 0, length: 2))
        attributed.addAttribute(.link, value: URL(string: "https://www.rakuten-sec.co.jp/")!, range: NSRange(location: 3, length: 30))
        testWriteDocX(attributedString: attributed)
        
        
    }

    func test山田電気FuriganaAttributed_ParagraphStyle_underline() {
        let attributed=yamadaDenkiString
        //        let style=NSParagraphStyle.default
        //        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let underlineStyle:NSUnderlineStyle = [.single,.byWord]
        attributed.addAttribute(.underlineStyle, value: underlineStyle.rawValue, range:NSRange(location: 0, length: attributed.length))
        testWriteDocX(attributedString: attributed)
        
        
    }
    
    func test山田電気FuriganaAttributed_ParagraphStyle_strikethrough() {
        let attributed=yamadaDenkiString
        //        let style=NSParagraphStyle.default
        //        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let underlineStyle:NSUnderlineStyle = [.single]
        attributed.addAttribute(.strikethroughStyle, value: underlineStyle.rawValue, range:NSRange(location: 0, length: attributed.length))
        testWriteDocX(attributedString: attributed)
        
        sleep(1)
    }
    
    func test山田電気FuriganaAttributed_ParagraphStyle_backgroundColor() {
        let attributed=yamadaDenkiString
        let style=NSMutableParagraphStyle()
        style.setParagraphStyle(NSParagraphStyle.default)
        style.alignment = .center
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        
        attributed.addAttribute(.backgroundColor, value: NSColor.blue, range:NSRange(location: 0, length: attributed.length))
        testWriteDocX(attributedString: attributed)
        
        sleep(1)
    }
    
    func testMultipage(){
        let longString = """
            1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            2. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            3. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            4. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            
            5. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            """
        let attributed=NSAttributedString(string: longString, attributes: [.font:NSFont.systemFont(ofSize: 20)])
        testWriteDocX(attributedString: attributed)
        
    }
    


    func testImage() throws{
        let longString = """
            1. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        """
#if SWIFT_PACKAGE
        let imageURL=try XCTUnwrap(Bundle.module.url(forResource: "Picture1", withExtension: "png"))
#else
        let imageURL=try XCTUnwrap(Bundle(for: DocX_iOS_Tests.self).url(forResource: "Picture1", withExtension: "png"))
#endif
        let imageData=try XCTUnwrap(Data(contentsOf: imageURL), "Image not found")
        let attachement=NSTextAttachment(data: imageData, ofType: kUTTypePNG as String)
        let attributed=NSAttributedString(string: longString, attributes: [.foregroundColor: NSColor.green])
        let imageString=NSAttributedString(attachment: attachement)
        let result=NSMutableAttributedString()
        result.append(attributed)
        result.append(imageString)
        testWriteDocX(attributedString: result)
    }

    
    @available(iOS 15, *)
    func testAttributed(){
        var att=AttributedString("Lorem ipsum dolor sit amet")
        att.strokeColor = .green
        att.strokeWidth = -2
        att.font = UIFont(name: "Helvetica", size: 12)
        att.foregroundColor = .gray
        let title=String(att.characters.prefix(10))
        let url=self.tempURL.appendingPathComponent(UUID().uuidString + "_myDocument_\(title)").appendingPathExtension("docx")
        print(url.absoluteString)
        do{
            try att.writeDocX(to: url)
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
        
#if SWIFT_PACKAGE
        let bundle=Bundle.module
#else
        let bundle=Bundle(for: DocX_iOS_Tests.self)
#endif
        
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
        let temp=self.tempURL.appendingPathComponent(UUID().uuidString + "_myDocument_\("Subscript")").appendingPathExtension("docx")
        try string.writeDocX(to: temp)
        

    }
    
}

#endif
