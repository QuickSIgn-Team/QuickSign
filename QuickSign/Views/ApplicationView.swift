import SwiftUI
import ZIPFoundation

struct DocumentsFolderIPA: Identifiable {
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
    @State private var ipas: [DocumentsFolderIPA] = []
    @State private var isLoading = false
    let sig = Signer.shared
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        ForEach(ipas) { ipa in
                            if ipa.ipaName.hasSuffix(".ipa") {
                                appStack(appName: ipa.appName, ipaName: ipa.ipaName, appVersion: ipa.appVersion, fileSize: ipa.ipaSize, icon: ipa.icon)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    } footer: {
                        if ipas.isEmpty && !isLoading {
                            Text("You don't have any IPAs imported.")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: refreshFiles) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: importIpa) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
            .overlay(
                Group {
                    if isLoading {
                        VStack {
                            Spacer()
                            ProgressView("Loading...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding()
                                .background(Color("LoadingColor").opacity(0.8)) // this color only work on dark mode for now
                                .cornerRadius(10)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .frame(maxWidth: 150, maxHeight: 150)
                        .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                    }
                }
            )
            
            .navigationTitle("Applications")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refreshFiles()
                checkTemp()
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let ipaToDelete = ipas[index]
            ipas.remove(at: index)
            let ipaPath = "\(documentsPath)/\(ipaToDelete.ipaName)"
            do {
                try FileManager.default.removeItem(atPath: ipaPath)
            } catch {
                print("Error deleting file: \(error.localizedDescription)")
            }
        }
    }
    
    private func refreshFiles() {
        isLoading = true
        Task {
            await fetchFiles()
            isLoading = false
        }
    }
    
    private func fetchFiles() async {
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(atPath: documentsPath)
            let filteredContents = folderContents.filter { $0.hasSuffix(".ipa") || $0.hasSuffix(".p12") || $0.hasSuffix(".mobileprovision") }

            self.ipas = await withTaskGroup(of: DocumentsFolderIPA?.self) { group in
                for item in filteredContents {
                    group.addTask {
                        let itemPath = "\(documentsPath)/\(item)"
                        do {
                            let attributes = try FileManager.default.attributesOfItem(atPath: itemPath)
                            let fileSize = attributes[.size] as! UInt64
                            let formattedFileSize = ByteCountFormatter().string(fromByteCount: Int64(fileSize))
                            let (appName, appVersion, icon) = await extractAppInfo(from: itemPath)
                            return DocumentsFolderIPA(ipaName: item, ipaSize: formattedFileSize, icon: icon, appName: appName ?? item, appVersion: appVersion ?? "Unknown")
                        } catch {
                            print("Error fetching file attributes: \(error.localizedDescription)")
                            return nil
                        }
                    }
                }
                return await group.reduce(into: [DocumentsFolderIPA]()) { result, folder in
                    if let folder = folder {
                        result.append(folder)
                    }
                }
            }
        } catch {
            print("Error reading directory: \(error.localizedDescription)")
            self.ipas = []
        }
    }
    
    private func checkTemp() {
        let tempDir = "\(documentsPath)/temp"
        var isDirectory: ObjCBool = true
        
        do {
            if FileManager.default.fileExists(atPath: tempDir, isDirectory: &isDirectory) {
                try FileManager.default.removeItem(atPath: tempDir)
            }
        } catch {
            UIApplication.shared.alert(title: "Error Deleting temp!", body: "Error: \(error.localizedDescription)")
        }
    }
    
    private func importIpa() {
        documentPickerDelegate = DocumentPickerDelegate { selectedURL in
            self.selectedIpaURL = selectedURL
            
            do {
                let destinationURL = URL(fileURLWithPath: documentsPath).appendingPathComponent(selectedURL!.lastPathComponent)
                try FileManager.default.copyItem(at: selectedURL!, to: destinationURL) // FORCE UNWAP RRAHHH
                refreshFiles()
            } catch {
                UIApplication.shared.alert(title: "Error Importing IPA!", body: "Error: \(error.localizedDescription)")
            }
        }
        showDocumentPickerIPA(delegate: documentPickerDelegate!)
    }
    
    private func extractAppInfo(from ipaPath: String) async -> (appName: String?, appVersion: String?, icon: UIImage?) {
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
                    let appName = PlistHelper.extractAppName(from: url)
                    let appVersion = PlistHelper.extractAppVersion(from: url)
                    let icon = extractIcon(from: url)
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
            if FileManager.default.fileExists(atPath: iconURL.path), let image = UIImage(contentsOfFile: iconURL.path) {
                return image
            }
        }
        
        return nil
    }
    
    private func appStack(appName: String, ipaName: String, appVersion: String, fileSize: String, icon: UIImage?) -> some View {
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
                Text("\(ipaName) | \(appName)")
                    .bold()
                    .font(.system(size: 16))
                Text("\(appVersion) • \(fileSize)")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            Button("Sign") {
                let signIpa = sig.signIpa(ipaURL: URL(fileURLWithPath: "\(documentsPath)/\(ipaName)"), certURL: URL(fileURLWithPath: "\(documentsPath)/cert.p12"))
                
                if signIpa {
                    UIApplication.shared.alert(title: "success", body: "ok")
                } else {
                    UIApplication.shared.alert(title: "error", body: "not ok")
                }
            }
            .buttonStyle(.bordered)
            .cornerRadius(20)
        }
    }
}

#Preview {
    ApplicationView()
}
