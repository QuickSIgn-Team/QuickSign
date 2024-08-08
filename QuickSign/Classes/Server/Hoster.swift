//
//  Hoster.swift
//  QuickSign
//
//  Created by Constantin Clerc on 9/8/24.
//

import Telegraph
import Foundation

func runServer() {
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    let server = Server()
    try! server.start(port: 9000)
    server.serveDirectory(URL(fileURLWithPath: "\(documentsPath)/temp/tempext"), "/tempWeb") // we basically dont need whats in temp appart from tempext
    server.route(.GET, "status") { (.ok, "Server is running") }
}
