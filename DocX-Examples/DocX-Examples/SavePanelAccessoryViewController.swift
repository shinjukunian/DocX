//
//  SavePanelAccessoryViewController.swift
//  DocX-Examples-macOS
//
//  Created by Morten Bertz on 2019/03/12.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Cocoa

class SavePanelAccessoryViewController: NSViewController {
    
    @objc dynamic private var selectedItem:Int=0
    
    enum SaveMode:Int{
        case docx, cocoa
    }
    
    var selectedSaveMode:SaveMode{
        return SaveMode(rawValue: self.selectedItem) ?? .cocoa
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
