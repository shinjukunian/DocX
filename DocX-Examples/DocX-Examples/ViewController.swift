//
//  ViewController.swift
//  DocX-Examples
//
//  Created by Morten Bertz on 2019/03/12.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import Cocoa
import DocX

class ViewController: NSViewController,NSMenuItemValidation {

    @IBOutlet weak var textView:NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(saveDocument(_:)){
            return self.textView.attributedString().length > 0
        }
        return false
    }
    
    @IBAction func saveDocument(_ sender:Any){
        guard let window=self.view.window else{return}
        let panel=NSSavePanel()
        panel.allowedFileTypes=[docXUTIType]
        panel.isExtensionHidden=false
        let accessory=SavePanelAccessoryViewController(nibName: nil, bundle: nil)
        panel.accessoryView=accessory.view
        panel.beginSheetModal(for: window, completionHandler: {response in
            guard let url=panel.url else{return}
            
            switch response{
            case .OK:
                do{
                    let string=self.textView.attributedString()
                    switch accessory.selectedSaveMode{
                    case .cocoa:
                        let data=try string.data(from: NSRange(location: 0, length: string.length), documentAttributes: [.documentType:NSAttributedString.DocumentType.officeOpenXML])
                        try data.write(to: url, options: .atomic)
                    case .docx:
                          try string.writeDocX(to: url)
                    }
                }
                catch let error{
                    print(error)
                }
            default:
                break
            }
        })
    }

}

