//
//  Signer.swift
//  QuickSign
//
//  Created by haxi0 on 05.08.2024.
//

import ZSign
import ZIPFoundation
import Foundation
import Telegraph

class Signer {
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let fm = FileManager.default
    static let shared = Signer()
    
    func signIpa(ipaURL: URL, certURL: URL) -> Bool {
        let tempDir = "\(documentsPath)/temp"
        var isDirectory: ObjCBool = true
        
        do {
            if !fm.fileExists(atPath: tempDir, isDirectory: &isDirectory) {
                try fm.createDirectory(at: URL(fileURLWithPath: tempDir), withIntermediateDirectories: true)
            }
            
            try fm.copyItem(at: ipaURL, to: URL(fileURLWithPath: "\(documentsPath)/temp/temp.ipa"))
            try fm.unzipItem(at: URL(fileURLWithPath: "\(documentsPath)/temp/temp.ipa"), to: URL(fileURLWithPath: "\(documentsPath)/temp/tempext"))
            
            zsign("\(documentsPath)/temp/tempext/Payload/Delta.app", "\(documentsPath)/cert.p12", "\(documentsPath)/cert.p12", "\(documentsPath)/cert.mobileprovision", "iApps0101", "", "")
            
            try fm.zipItem(at: URL(fileURLWithPath: "\(documentsPath)/temp/tempext/Payload"), to: URL(fileURLWithPath: "\(documentsPath)/temp/tempext/tempsigned.ipa"))
            
            setupAndDeploy()
            
            return true
        } catch {
            return false
        }
    }
    
    func setupAndDeploy() {
        let server = Server()
        try! server.start(port: 9000)
        server.serveDirectory(URL(fileURLWithPath: "\(documentsPath)/temp"), "/tempWeb")
        server.route(.GET, "status") { (.ok, "Server is running") }
    }
}
