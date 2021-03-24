//
//  DocXWriter.swift
//  
//
//  Created by Morten Bertz on 2021/03/24.
//

import Foundation

public class DocXWriter{
    public class func write(pages:[NSAttributedString], to url:URL) throws{
        guard let first=pages.first else {return}
        let result=NSMutableAttributedString(attributedString: first)
        let pageSeperator=NSAttributedString(string: "\r", attributes: [.breakType:BreakType.page])
        
        for page in pages.dropFirst(){
            result.append(pageSeperator)
            result.append(page)
        }
        
        try result.writeDocX(to: url)
    }
}
