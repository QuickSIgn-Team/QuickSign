import SwiftUI

struct DocumentsFolder: Identifiable {
    let id = UUID()
    let ipaName: String
    let ipaSize: String
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
                        appStack(fileName: ipa.ipaName, fileSize: ipa.ipaSize)
                    }
                    .onDelete { indices in
                        for index in indices {
                            if ipas.indices.contains(index) {
                                let ipaToDelete = ipas[index]
                                
                                ipas.remove(at: index)
                                
                                let ipaPath = "\(documentsPath)/\(ipaToDelete.ipaName)"
                                do {
                                    try fm.removeItem(atPath: ipaPath)
                                } catch {
                                    UIApplication.shared.alert(title: "Error Deleting IPA", body: "Error: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                } // mb a footer
                .navigationTitle("QuickSign")
                .navigationBarTitleDisplayMode(.inline)
            }
            .toolbar {
                Button(action: {
                    Task {
                        await refreshFiles()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                
                Button(action: {
                    importIpa()
                }) {
                    Image(systemName: "square.and.arrow.down")
                }
            }
        }
        .onAppear {
            Task {
                await refreshFiles()
            }
        }
    }
    
    private func refreshFiles() async {
        do {
            let folderContents = try fm.contentsOfDirectory(atPath: documentsPath)
            
            self.ipas = try await withThrowingTaskGroup(of: DocumentsFolder?.self) { group in
                for item in folderContents {
                    group.addTask {
                        let itemPath = documentsPath + "/" + item
                        var fileSize: UInt64 = 0
                        
                        guard item.hasSuffix(".ipa") else {
                            return nil
                        }
                        
                        do {
                            let attr = try FileManager.default.attributesOfItem(atPath: itemPath)
                            fileSize = attr[FileAttributeKey.size] as! UInt64
                            
                            let dict = attr as NSDictionary
                            fileSize = dict.fileSize()
                        } catch {
                            UIApplication.shared.alert(title: "Error Getting File Size of the IPA!", body: "Error: \(error.localizedDescription)")
                            return DocumentsFolder(ipaName: "", ipaSize: "")
                        }
                        
                        let byteCountFormatter = ByteCountFormatter()
                        byteCountFormatter.allowedUnits = [.useKB, .useMB, .useGB]
                        byteCountFormatter.countStyle = .file
                        let formattedFileSize = byteCountFormatter.string(fromByteCount: Int64(fileSize))
                        
                        return DocumentsFolder(ipaName: item, ipaSize: formattedFileSize)
                    }
                }
                
                var results: [DocumentsFolder] = []
                for try await ipa in group {
                    if let ipa = ipa {
                        results.append(ipa)
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
                    await refreshFiles()
                }
            } catch {
                UIApplication.shared.alert(title: "Error Importing IPA!", body: "Error: \(error.localizedDescription)")
            }
        }
        showDocumentPicker(delegate: documentPickerDelegate!)
    }
    
    private func appStack(fileName: String, fileSize: String) -> some View {
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
                Text("69.0 • \(fileSize)")
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
