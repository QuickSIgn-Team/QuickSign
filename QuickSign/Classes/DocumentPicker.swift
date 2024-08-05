import UIKit
import MobileCoreServices

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    var onDocumentPicked: (URL) -> Void
    
    init(onDocumentPicked: @escaping (URL) -> Void) {
        self.onDocumentPicked = onDocumentPicked
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else {
            return
        }
        
        // Start accessing the security-scoped resource
        if selectedURL.startAccessingSecurityScopedResource() {
            defer {
                // Stop accessing the security-scoped resource
                selectedURL.stopAccessingSecurityScopedResource()
            }
            
            onDocumentPicked(selectedURL)
        } else {
            print("Could not access security scoped resource")
        }
    }
}

func showDocumentPicker(delegate: DocumentPickerDelegate) {
    let fileTypes = ["com.apple.itunes.ipa"]
    let documentPicker = UIDocumentPickerViewController(
        documentTypes: fileTypes,
        in: .open
    )
    documentPicker.allowsMultipleSelection = false
    documentPicker.delegate = delegate
    UIApplication.shared.windows.first?.rootViewController?.present(
        documentPicker,
        animated: true,
        completion: nil
    )
}
