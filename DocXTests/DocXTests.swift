//
//  DocXTests.swift
//  DocXTests
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import XCTest
@testable import DocX

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
            var readAttributes:NSDictionary?=nil
            let docXString=try NSAttributedString(url: url, options: [:], documentAttributes: &readAttributes)
            guard let attributes=readAttributes as? [String:Any] else{
                XCTFail()
                return
            }
            XCTAssertEqual(attributes[NSAttributedString.DocumentAttributeKey.documentType.rawValue] as! String, NSAttributedString.DocumentType.officeOpenXML.rawValue)
            let string=docXString.string
            print(string)
            XCTAssertEqual(docXString.string, string)
            
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
        let attributed=NSAttributedString(string: string, attributes: [.font:NSFont.systemFont(ofSize: NSFont.systemFontSize)])
        testWriteDocX(attributedString: attributed)
    }

    func test山田FuriganaAttributed() {
        let string="山田"
        let furigana="やまだ"
        let ruby=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, furigana as CFString, [kCTRubyAnnotationSizeFactorAttributeName:0.5] as CFDictionary)
        let rubyKey=NSAttributedString.Key(kCTRubyAnnotationAttributeName as String)
        let attributed=NSAttributedString(string: string, attributes: [.font:NSFont.systemFont(ofSize: NSFont.systemFontSize), rubyKey:ruby])
        testWriteDocX(attributedString: attributed)
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

    func test山田電気FuriganaAttributed_ParagraphStyle_bold() {
        let attributed=yamadaDenkiString
        let style=NSParagraphStyle.default
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let boldFont=NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        attributed.addAttribute(.font, value: boldFont, range: NSRange(location: 0, length: 2))
        testWriteDocX(attributedString: attributed)

    }

    //crashes the cocoa docx writer!
    func test山田電気FuriganaAttributed_ParagraphStyle_underline() {
        let attributed=yamadaDenkiString
//        let style=NSParagraphStyle.default
//        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let underlineStyle:NSUnderlineStyle = .single
        attributed.addAttribute(.underlineStyle, value: underlineStyle, range:NSRange(location: 0, length: attributed.length))
        testWriteDocX(attributedString: attributed)
    }

    func test山田電気FuriganaAttributed_ParagraphStyle_backgroundColor() {
        let attributed=yamadaDenkiString
        let style=NSMutableParagraphStyle()
        style.setParagraphStyle(NSParagraphStyle.default)
        style.alignment = .center
        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))

        attributed.addAttribute(.backgroundColor, value: NSColor.blue, range:NSRange(location: 0, length: attributed.length))
        testWriteDocX(attributedString: attributed)

    }
    func test山田電気FuriganaAttributed_ParagraphStyle_strikethrough() {
        let attributed=yamadaDenkiString
        //        let style=NSParagraphStyle.default
        //        attributed.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: attributed.length))
        let underlineStyle:NSUnderlineStyle = [.single]
        attributed.addAttribute(.strikethroughStyle, value: underlineStyle, range:NSRange(location: 0, length: attributed.length))
        testWriteDocX(attributedString: attributed)
        
        sleep(1)
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
        
        sleep(1)
    }
    
    
    
    

}
