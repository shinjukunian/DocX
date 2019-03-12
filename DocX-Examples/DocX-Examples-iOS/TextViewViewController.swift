//
//  ViewController.swift
//  DocX-Examples-iOS
//
//  Created by Morten Bertz on 2019/03/12.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import UIKit
import DocX
import QuickLook


protocol DocXPreviewing:class,QLPreviewControllerDelegate,QLPreviewControllerDataSource{
    var documentURL:URL? {get set}
    var attributedText:NSAttributedString? {get}
}

class DocXPreviewingViewController:UIViewController,DocXPreviewing{
    var documentURL:URL?
    var attributedText: NSAttributedString?
    
    @objc func previewControllerDidDismiss(_ controller: QLPreviewController) {
        if let url=self.documentURL{
            try? FileManager.default.removeItem(at: url)
            self.documentURL=nil
        }
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.documentURL != nil ? 1 : 0
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let url=self.documentURL else{return NSURL(fileURLWithPath: "")}
        return url as NSURL
    }
    
    @IBAction func preview(_ sender:UIBarButtonItem){
        guard let string=self.attributedText else{return}
        let previewController=QLPreviewController()
        previewController.dataSource=self
        previewController.delegate=self
        let temp=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("docx")
        do{
            try string.writeDocX(to: temp)
            self.documentURL=temp
            self.navigationController?.pushViewController(previewController, animated: true)
        }
        catch let error{
            print(error)
        }
    }
    
    @IBAction func save(_ sender:UIBarButtonItem){
        guard let text=self.attributedText else{return}
        let item=DocXActivityItemProvider(attributedString: text)
        let activityController=UIActivityViewController(activityItems: [item], applicationActivities: nil)
        activityController.popoverPresentationController?.barButtonItem=sender
        activityController.completionWithItemsHandler={type, completed, returnedItem,error in
            if let url=item.placeholderItem as? URL{
                try? FileManager.default.removeItem(at: url)
            }
        }
        self.present(activityController, animated: true, completion: nil)
    }
    
}


class TextViewViewController: DocXPreviewingViewController {
    
    @IBOutlet weak var textView:UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url=Bundle.main.url(forResource: "TestDocument", withExtension: "rtf"),
            let string=try? NSAttributedString(url: url, options: [:], documentAttributes: nil) else{return}
        self.textView.attributedText=string
    }
    
    override var attributedText: NSAttributedString?{
        get{return self.textView.attributedText}
        set{self.textView.attributedText=newValue}
    }
    

    
}

