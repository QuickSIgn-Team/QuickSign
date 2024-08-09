//
//  Hoster.swift
//  QuickSign
//
//  Created by Constantin Clerc on 9/8/24.
//

import Swifter
import Foundation
import Dispatch
import UIKit

func runServer() {
    let dispatchGroup = DispatchGroup()
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let server = HttpServer()
    keepServerAlive = true
    
    server["/:path"] = shareFilesFromDirectory("\(documentsPath)/temp/tempext")    
    dispatchGroup.enter()
    
    do {
        try server.start(9090, forceIPv4: true)
        print("Server has started (port = \(try server.port())). Try to connect now...")
        guard let url = URL(string: "http://localhost:9090/install.plist") else {
            print("Invalid URL")
            return
        }

        // Create and start a data task
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            
            if let data = data, let content = String(data: data, encoding: .utf8) {
                print("Content:\n\(content)")
            } else {
                print("No data or failed to decode")
            }
        }.resume()
        UIApplication.shared.open(URL(string: "itms-services://?action=download-manifest&url=https://cclerc.ch/install.plist")!)// im just going to die sorry
        DispatchQueue.global().async {
            while keepServerAlive {
                sleep(1)
            }
            server.stop()
            print("Server has stopped.")
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
    } catch {
        print(error)
        dispatchGroup.leave()
    }
}
