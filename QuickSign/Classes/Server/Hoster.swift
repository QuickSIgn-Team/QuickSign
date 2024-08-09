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
