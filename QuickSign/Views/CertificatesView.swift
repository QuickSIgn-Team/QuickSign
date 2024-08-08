//
//  CertificatesView.swift
//  QuickSign
//
//  Created by haxi0 on 09.08.2024.
//

import SwiftUI

struct DocumentsFolderCert: Identifiable {
    let id = UUID()
    let certName: String
}

struct CertificatesView: View {
    @State private var selectedCertURL: URL?
    @State private var documentPickerDelegate: DocumentPickerDelegate?
    @State private var certs: [DocumentsFolderCert] = []
    @State private var isLoading = false
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section {
                        ForEach(certs) { cert in
                            if cert.certName.hasSuffix(".p12") || cert.certName.hasSuffix(".mobileprovision") {
                                Text(cert.certName)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    } footer: {
                        if certs.isEmpty && !isLoading {
                            Text("You don't have any Certificates imported.")
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
                    Button(action: importCert) {
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
            
            .navigationTitle("Certificates")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: refreshFiles)
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let certToDelete = certs[index]
            certs.remove(at: index)
            let certPath = "\(documentsPath)/\(certToDelete.certName)"
            do {
                try FileManager.default.removeItem(atPath: certPath)
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
            let filteredContents = folderContents.filter { $0.hasSuffix(".p12") || $0.hasSuffix(".mobileprovision") }

            self.certs = await withTaskGroup(of: DocumentsFolderCert?.self) { group in
                for item in filteredContents {
                    group.addTask {
                        return DocumentsFolderCert(certName: item)
                    }
                }
                return await group.reduce(into: [DocumentsFolderCert]()) { result, folder in
                    if let folder = folder {
                        result.append(folder)
                    }
                }
            }
        } catch {
            print("Error reading directory: \(error.localizedDescription)")
            self.certs = []
        }
    }
    
    private func importCert() {
        documentPickerDelegate = DocumentPickerDelegate { selectedURL in
            self.selectedCertURL = selectedURL
            
            do {
                let destinationURL = URL(fileURLWithPath: documentsPath).appendingPathComponent(selectedURL!.lastPathComponent)
                try FileManager.default.copyItem(at: selectedURL!, to: destinationURL) // FORCE UNWAP RRAHHH
                refreshFiles()
            } catch {
                UIApplication.shared.alert(title: "Error Importing Certificate!", body: "Error: \(error.localizedDescription)")
            }
        }
        showDocumentPickerCert(delegate: documentPickerDelegate!)
    }
    
    private func certStack(appName: String, certName: String, appVersion: String, fileSize: String, icon: UIImage?) -> some View {
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
                Text("\(certName) | \(appName)")
                    .bold()
                    .font(.system(size: 16))
                Text("\(appVersion) • \(fileSize)")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            Button("Sign") {
                // sign action here...
            }
            .buttonStyle(.bordered)
            .cornerRadius(20)
        }
    }
}

#Preview {
    CertificatesView()
}
