//
//  DocXTests.swift
//  DocXTests
//
//  Created by Morten Bertz on 2019/03/10.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import XCTest
@testable import DocX
@testable import ZipArchive

class DocXTests: XCTestCase {

    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    func testUnzip(){
        guard let dummyDoc=Bundle(for: DocXTests.self).url(forResource: "blank", withExtension: "docx") else{
            XCTFail()
            fatalError()
        }
        let temp=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let success=SSZipArchive.unzipFile(atPath: dummyDoc.path, toDestination: temp.path)
        XCTAssert(success == true)
        let outZip=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_rezip").appendingPathExtension("docx")
        let zipSuccess=SSZipArchive.createZipFile(atPath: outZip.path, withContentsOfDirectory: temp.path)
        XCTAssert(zipSuccess == true)
    }
    
    func testWriteXML(){
        let string=""
        let attributedString=NSAttributedString(string: string)
        do{
            let xml=try attributedString.docXDocument()
            let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("xml")
            try xml.write(to: url, atomically: true, encoding: .utf8)
           
        }
        catch let error{
            XCTFail(error.localizedDescription)
        }
    }
    
    func testWriteDocX(attributedString:NSAttributedString){
        
        do{
            let url=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "_myDocument_\(attributedString.string.prefix(10))").appendingPathExtension("docx")
            try attributedString.saveTo(url: url)
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
        do{
            testWriteDocX(attributedString: attributedString)
            
        }
        catch let error{
            XCTFail(error.localizedDescription)
        }
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
    
    
    

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
