import SwiftUI

struct DocumentsFolder: Identifiable {
    let id = UUID()
    let ipaName: String
}

struct ApplicationView: View {
    @State private var selectedIpaURL: URL?
    @State private var documentPickerDelegate: DocumentPickerDelegate?
    @State private var ipas: [DocumentsFolder] = []
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let fm = FileManager.default
    let sig = Signer.shared
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(ipas) { ipa in
                        appStack(fileName: ipa.ipaName)
                    }
                } // mb a footer
                .navigationTitle("QuickSign")
                .navigationBarTitleDisplayMode(.inline)
            }
            .toolbar {
                Button(action: {
                    importIpa()
                }) {
                    Image(systemName: "square.and.arrow.down")
                }
            }
            .refreshable {
                await refreshFolders()
            }
        }
        .onAppear {
            Task {
                await refreshFolders()
            }
        }
    }
    
    private func refreshFolders() async {
        do {
            let folderContents = try fm.contentsOfDirectory(atPath: documentsPath)
            
            self.ipas = try await withThrowingTaskGroup(of: DocumentsFolder?.self) { group in
                for item in folderContents {
                    group.addTask {
                        let itemPath = documentsPath + "/" + item
                        
                        guard item.hasSuffix(".ipa") else {
                            return nil
                        }
                        
                        return DocumentsFolder(ipaName: item)
                    }
                }
                
                var results: [DocumentsFolder] = []
                for try await folder in group {
                    if let folder = folder {
                        results.append(folder)
                    }
                }
                return results
            }
        } catch {
            UIApplication.shared.alert(title: "Error Refreshing IPA!", body: "Error: \(error.localizedDescription)")
            self.ipas = []
        }
    }
    
    private func importIpa() {
        documentPickerDelegate = DocumentPickerDelegate { selectedURL in
            self.selectedIpaURL = selectedURL
            
            do {
                let destinationURL = URL(fileURLWithPath: documentsPath).appendingPathComponent(selectedIpaURL!.lastPathComponent)
                try fm.copyItem(at: selectedIpaURL!, to: destinationURL)
                
                Task {
                    await refreshFolders()
                }
            } catch {
                UIApplication.shared.alert(title: "Error Importing IPA!", body: "Error: \(error.localizedDescription)")
            }
        }
        showDocumentPicker(delegate: documentPickerDelegate!)
    }
    
    private func appStack(fileName: String) -> some View {
        HStack {
            Image("DefaultIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white, lineWidth: 0.5)
                        .opacity(0.3)
                )
            
            VStack(alignment: .leading, spacing: 1) {
                Text(fileName)
                    .bold()
                    .font(.system(size: 16))
                Text("69.0 • App Size")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                // Placeholder
            }) {
                Text("Sign")
                    .bold()
                    .frame(width: 58 , height: 20, alignment: .center)
            }
            .buttonStyle(.bordered)
            .cornerRadius(20)
        }
    }
}

#Preview {
    ApplicationView()
}
