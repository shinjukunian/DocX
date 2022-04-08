//
//  MarkupEditingViewController.swift
//  DocX-Examples-iOS
//
//  Created by Morten Bertz on 2022/04/07.
//  Copyright © 2022 telethon k.k. All rights reserved.
//

import Foundation
import SwiftUI
import DocX

struct DocumentItem:Equatable,Identifiable,Hashable{
    var id: String{
        return url.absoluteString
    }
    let url:URL
}

@available(iOS 15, *)
struct MarkupEditingView: View {
    
    @State var text:String = "This is a **Markdown** _string_."
    @State private var showPreview = false
    @State private var attributedText:AttributedString?
    
    @State private var item:DocumentItem?
    
    var body: some View {
        NavigationView{
            VStack{
                ScrollView{
                    VStack{
                        if let att=attributedText{
                            Text(att)
                        }
                        else{
                            Text("Invalid Markdown")
                        }
                        Spacer()
                    }
                    
                }
                Divider()
                ScrollView{
                    TextEditor(text: $text)
                }
            }
            .onChange(of: text, perform: {newValue in
                parse()
            })
            .navigationTitle("Markdown Editor")
            .toolbar{
                ToolbarItem(placement: .automatic, content: {
                    Button(action: {
                        showPreview=true

                        item=try? writeDocX()
                        
                    }, label: {
                        Label(title: {
                            Text("Preview")
                        }, icon: {
                            Image(systemName: "doc.text.magnifyingglass")
                        })
                    }).disabled(attributedText == nil)
                })
            }
            .onAppear{
                parse()
            }
            .fullScreenCover(item: $item, onDismiss: {
                if let item=item{
                    try? FileManager.default.removeItem(at: item.url)
                }
                item=nil
            }, content: {urlItem in
                let show=Binding(get: {
                    return item == nil
                }, set: {nV in
                    if nV == false{
                        item=nil
                    }
                })
                DocumentPreview(show, url: urlItem.url)
            })
        }
        
    }
    
    func parse(){
        attributedText=try? AttributedString(markdown: text)
    }
    
    func writeDocX()throws ->DocumentItem?{
        guard let attributedText = attributedText else {
            return nil
        }

        let tempURL=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("docx")
        try attributedText.writeDocX(to: tempURL)
        return DocumentItem(url: tempURL)
    }
    
}

@available(iOS 15.0, *)
struct MarkupEditingView_Previews: PreviewProvider {
    static var previews: some View {
        MarkupEditingView()
    }
}


@available(iOS 15.0, *)
class MarkupEditingViewHosting:UIHostingController<MarkupEditingView>{
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: MarkupEditingView())
    }
    
}

@available(iOS 13.0, *)
struct DocumentPreview: UIViewControllerRepresentable {
    private var isActive: Binding<Bool>
    private let viewController = UIViewController()
    private let docController: UIDocumentInteractionController

    init(_ isActive: Binding<Bool>, url: URL) {
        self.isActive = isActive
        self.docController = UIDocumentInteractionController(url: url)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPreview>) -> UIViewController {
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<DocumentPreview>) {
        if self.isActive.wrappedValue && docController.delegate == nil { // to not show twice
            docController.delegate = context.coordinator
            DispatchQueue.main.async {
                self.docController.presentPreview(animated: true)

            }
        }
    }

    func makeCoordinator() -> Coordintor {
        return Coordintor(owner: self)
    }

    final class Coordintor: NSObject, UIDocumentInteractionControllerDelegate { // works as delegate
        let owner: DocumentPreview
        init(owner: DocumentPreview) {
            self.owner = owner
        }
        func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
            return owner.viewController
        }

        func documentInteractionControllerDidEndPreview(_ controller: UIDocumentInteractionController) {
            controller.delegate = nil // done, so unlink self
            owner.isActive.wrappedValue = false // notify external about done
        }
    }
}
