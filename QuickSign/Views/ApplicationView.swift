import SwiftUI
import ZIPFoundation

struct DocumentsFolder: Identifiable {
    let id = UUID()
    let ipaName: String
    let ipaSize: String
    let icon: UIImage?
    let appName: String
    let appVersion: String
}

struct ApplicationView: View {
    @State private var selectedIpaURL: URL?
    @State private var documentPickerDelegate: DocumentPickerDelegate?
    @State private var ipas: [DocumentsFolder] = []
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let fm = FileManager.default
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(ipas) { ipa in
                        appStack(appName: ipa.appName, appVersion: ipa.appVersion, fileSize: ipa.ipaSize, icon: ipa.icon)
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
                }
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
                            
                            let byteCountFormatter = ByteCountFormatter()
                            byteCountFormatter.allowedUnits = [.useKB, .useMB, .useGB]
                            byteCountFormatter.countStyle = .file
                            let formattedFileSize = byteCountFormatter.string(fromByteCount: Int64(fileSize))
                            
                            let (appName, appVersion, icon) = extractAppInfo(from: itemPath)
                            
                            return DocumentsFolder(ipaName: item, ipaSize: formattedFileSize, icon: icon, appName: appName ?? item, appVersion: appVersion ?? "Unknown")
                        } catch {
                            UIApplication.shared.alert(title: "Error Getting File Size of the IPA!", body: "Error: \(error.localizedDescription)")
                            return DocumentsFolder(ipaName: item, ipaSize: "Unknown Size", icon: nil, appName: item, appVersion: "Unknown")
                        }
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
    
    private func extractAppInfo(from ipaPath: String) -> (appName: String?, appVersion: String?, icon: UIImage?) {
        let fileURL = URL(fileURLWithPath: ipaPath)
        
        let unzipPath = NSTemporaryDirectory() + UUID().uuidString
        let unzipURL = URL(fileURLWithPath: unzipPath)
        
        do {
            try FileManager.default.createDirectory(at: unzipURL, withIntermediateDirectories: true, attributes: nil)
            try FileManager.default.unzipItem(at: fileURL, to: unzipURL)
            
            defer {
                try? FileManager.default.removeItem(at: unzipURL)
            }
            
            let payloadURL = unzipURL.appendingPathComponent("Payload")
            let payloadContents = try FileManager.default.contentsOfDirectory(at: payloadURL, includingPropertiesForKeys: nil)
            
            for url in payloadContents {
                if url.pathExtension == "app" {
                    let appBundleURL = url
                    
                    let appName = PlistHelper.extractAppName(from: appBundleURL)
                    let appVersion = PlistHelper.extractAppVersion(from: appBundleURL)
                    let icon = extractIcon(from: appBundleURL)
                    
                    return (appName, appVersion, icon)
                }
            }
        } catch {
            print("Error extracting app info: \(error)")
        }
        
        return (nil, nil, nil)
    }
    
    private func extractIcon(from appBundleURL: URL) -> UIImage? {
        let iconFiles = ["AppIcon60x60@2x.png", "AppIcon76x76@2x.png", "AppIcon120x120.png", "AppIcon180x180.png"]
        
        for iconFile in iconFiles {
            let iconURL = appBundleURL.appendingPathComponent(iconFile)
            if FileManager.default.fileExists(atPath: iconURL.path) {
                return UIImage(contentsOfFile: iconURL.path)
            }
        }
        
        return nil
    }
    
    private func appStack(appName: String, appVersion: String, fileSize: String, icon: UIImage?) -> some View {
        HStack {
            if let icon = icon {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white, lineWidth: 0.5)
                            .opacity(0.3)
                    )
            } else {
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
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(appName)
                    .bold()
                    .font(.system(size: 16))
                Text("\(appVersion) • \(fileSize)")
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
