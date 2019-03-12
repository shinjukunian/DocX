//
//  ComplexTextViewController.swift
//  DocX-Examples-iOS
//
//  Created by Morten Bertz on 2019/03/12.
//  Copyright © 2019 telethon k.k. All rights reserved.
//

import UIKit
import CoreText

class ComplexTextViewController: DocXPreviewingViewController {

    @IBOutlet weak var rubyView:RubyView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let string=NSMutableAttributedString(string: "楽天証券\nhttps://www.rakuten-sec.co.jp/")
        string.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .body), range: NSRange(location: 0, length: string.length))
        string.addAttribute(.link, value: URL(string: "https://www.rakuten-sec.co.jp/") ?? "", range: NSRange(location: 5, length: 30))
        let rakutenRuby=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, "らくてん" as CFString, [kCTRubyAnnotationSizeFactorAttributeName:0.5, kCTForegroundColorAttributeName:UIColor.red] as CFDictionary)
        string.addAttribute(.ruby, value: rakutenRuby, range: NSRange(location: 0, length: 2))
        let shoken=CTRubyAnnotationCreateWithAttributes(.auto, .auto, .before, "しょうけん" as CFString, [kCTRubyAnnotationSizeFactorAttributeName:0.5, kCTForegroundColorAttributeName:UIColor.red] as CFDictionary)
        string.addAttribute(.ruby, value: shoken, range: NSRange(location: 2, length: 2))
        string.addAttribute(.foregroundColor, value: UIColor.red, range: NSRange(location: 0, length: 4))
        let paragraphStyle=NSMutableParagraphStyle()
        paragraphStyle.setParagraphStyle(NSParagraphStyle.default)
        paragraphStyle.alignment = .center
        paragraphStyle.paragraphSpacing=20
        string.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: string.length))
        self.attributedText=string
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.rubyView.attributedString=self.attributedText
    }
}

class RubyView:UIView{
    var attributedString:NSAttributedString?{
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let string=self.attributedString, let ctx=UIGraphicsGetCurrentContext() else{return}
        let framesetter=CTFramesetterCreateWithAttributedString(string as CFAttributedString)
        var fitRange:CFRange=CFRange(location: 0, length: 0)
        let inset:CGFloat=5
        let drawRect=rect.insetBy(dx: inset, dy: inset)
        let stringSize=CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0, length: string.length), [:] as CFDictionary, drawRect.size, &fitRange)
        ctx.translateBy(x: 0, y: rect.height)
        ctx.scaleBy(x: 1, y: -1)
        ctx.textMatrix=CGAffineTransform.identity
        ctx.translateBy(x: (rect.width-stringSize.width)/2, y: (rect.height-stringSize.height)/2)
        let path=CGPath(rect: CGRect(origin: .zero, size: stringSize), transform: nil)
        let frame=CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: string.length), path, [:] as CFDictionary)
        CTFrameDraw(frame, ctx)
    }
}
