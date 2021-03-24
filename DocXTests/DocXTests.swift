//
//  DocXTests.swift
//  DocXTests
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import XCTest

import DocX

#if os(macOS)
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
    
    
    
    func testWriteDocX(attributedString:NSAttributedString, useBuiltin:Bool = true){
        
        do{
            let url=self.tempURL.appendingPathComponent(UUID().uuidString + "_myDocument_\(attributedString.string.prefix(10))").appendingPathExtension("docx")
            try attributedString.writeDocX(to: url, useBuiltIn: useBuiltin)
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
        attributed.addAttribute(.underlineStyle, value: underlineStyle.rawValue, range:NSRange(location: 0, length: attributed.length))
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
        attributed.addAttribute(.strikethroughStyle, value: underlineStyle.rawValue, range:NSRange(location: 0, length: attributed.length))
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
        testWriteDocX(attributedString: attributed, useBuiltin: false)
        
        sleep(1)
    }
    
    
    
    
    func test_ParagraphStyle() {
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
        testWriteDocX(attributedString: attributed)
       
    }
    
    func testOutline(){
        let outlineString=NSAttributedString(string: "An outlined String\r", attributes: [.font:NSFont.systemFont(ofSize: 13),.strokeWidth:3,.strokeColor:NSColor.green, .foregroundColor:NSColor.blue, .backgroundColor:NSColor.orange])
        let outlinedAndStroked=NSMutableAttributedString(attributedString: outlineString)
        outlinedAndStroked.addAttribute(.strokeWidth, value: -3, range: NSRange(location: 0, length: outlinedAndStroked.length))
        let noBG=NSMutableAttributedString(attributedString: outlineString)
        noBG.removeAttribute(.backgroundColor, range: NSMakeRange(0, noBG.length))
        noBG.append(outlinedAndStroked)
        noBG.append(outlineString)
        
        testWriteDocX(attributedString: noBG)
    
    }
    
    func testMultiPage() {
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
        
        testWriteDocX(attributedString: result, useBuiltin: false)
       
    }
    
    func testMultiPageWriter() {
        
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
        
        do{
            try DocXWriter.write(pages: pages, to: url)
            
        }
        catch let error{
            XCTFail(error.localizedDescription)
        }
        
       
    }
    

}

#endif

