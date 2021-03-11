//
//  ContentView.swift
//  Memoji image genetator
//
//  Created by Haruki Nazawa on 2021/03/08.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var image: UIImage = UIImage()
    @State private var backgroundColor = Color.gray
    @State private var showingAlert: AlertItem?
    @State private var showMemojiEditor = true
    @State private var showActivityView = false
    
    init() {
        if (image.size.width != 0) {
            self.showMemojiEditor = false
        }
    }
    
    func saveImage() {
        let imageSaver = ImageSaver()
        
        imageSaver.successHandler = {
            self.showingAlert = AlertItem(alert: Alert(title: Text("Image saved.")))
        }
        imageSaver.errorHandler = {
            self.showingAlert = AlertItem(alert: Alert(title: Text("Faled to save image.")))
            print("Oops: \($0.localizedDescription)")
        }
        
        imageSaver.writeToPhotoAlbum(image: image.withBackground(color: UIColor(backgroundColor)))
    }
 
    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: image).background(backgroundColor)
                List {
                    ColorPicker("Background color", selection: $backgroundColor)
                    Button(action: {
                        self.showMemojiEditor = true
                    }, label: {
                        Text("Memoji")
                    })
                    .sheet(isPresented: $showMemojiEditor) {
                        NavigationView {
                            SwiftUIMemojiText(image: $image).onChange(of: image, perform: { value in
                                self.showMemojiEditor = false
                            })
                            .navigationBarTitle("Memoji")
                            .navigationBarItems(trailing: Button(action: {
                                self.showMemojiEditor = false
                            }, label: {
                                Text("Done")
                            }))
                        }
                    }
                }.listStyle(PlainListStyle())
            }
            .navigationBarItems(trailing: {
                Menu {
                    Button(action: {
                        saveImage()
                    }) {
                        Text("Save to camera roll")
                    }
                    Button(action: {
                        self.showActivityView = true
                    }) {
                        Text("Share")
                    }
                } label: {
                    Text("Export")
                }
            }())
            .alert(item: $showingAlert) { item in
                item.alert
            }
            .sheet(isPresented: $showActivityView) {
                ShareSheet(image: $image)
            }
        }
    }
}

struct AlertItem: Identifiable {
    var id = UUID()
    var alert: Alert
}

struct ShareSheet: UIViewControllerRepresentable {
    @Binding var image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityItems: [Any] = [image]

        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil)
        
        return controller
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {
    }
}

struct SwiftUIMemojiText: UIViewRepresentable {
    @Binding private var image: UIImage
    private var textView = MemojiTextView()
    
    init(image: Binding<UIImage>) {
        textView.allowsEditingTextAttributes = true
        textView.clearsOnInsertion = true
        self._image = image
    }
    
    func makeUIView(context: Context) -> MemojiTextView {
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ uiView: MemojiTextView, context: Context) {
    }
    
    func makeCoordinator() -> SwiftUIMemojiText.Coordinator {
        return Coordinator(image: $image)
    }
}

extension SwiftUIMemojiText {
    class Coordinator: NSObject, UITextViewDelegate {
        @Binding var image: UIImage
        
        init(image: Binding<UIImage>) {
            self._image = image
        }
        
        func textViewDidChange(_ textView: UITextView) {
            textView.attributedText.enumerateAttributes(in: NSMakeRange(0, textView.attributedText.length), options: []) { (attachment, range, _) in
                attachment.values.forEach({ (value) in
                    if ((value as? NSTextAttachment) != nil) {
                        let textAttachment: NSTextAttachment = value as! NSTextAttachment
                        self.image = textAttachment.image!
                        return
                    }
                })
            }
        }
    }
}

class MemojiTextView: UITextView {
    override var textInputContextIdentifier: String? { "" }
    
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return nil
    }
}

class ImageSaver: NSObject {
    var successHandler: (() -> Void)?
    var errorHandler: ((Error) -> Void)?

    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }

    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            errorHandler?(error)
        } else {
            successHandler?()
        }
    }
}

extension UIImage {
  func withBackground(color: UIColor, opaque: Bool = true) -> UIImage {
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale)
        
    guard let ctx = UIGraphicsGetCurrentContext(), let image = cgImage else { return self }
    defer { UIGraphicsEndImageContext() }
        
    let rect = CGRect(origin: .zero, size: size)
    ctx.setFillColor(color.cgColor)
    ctx.fill(rect)
    ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height))
    ctx.draw(image, in: rect)
        
    return UIGraphicsGetImageFromCurrentImageContext() ?? self
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
