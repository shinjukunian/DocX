//
//  Bundle+Extensions.swift
//  
//
//  Created by Morten Bertz on 2021/03/23.
//

import Foundation

#if SWIFT_PACKAGE
extension Bundle{
    class var blankDocumentURL:URL?{
        return Bundle.module.url(forResource: "blank", withExtension: nil)
    }
}
#else
extension Bundle{
    class var blankDocumentURL:URL?{
        return Bundle(for: DocumentRoot.self).url(forResource: "blank", withExtension: nil)
    }
}
#endif
