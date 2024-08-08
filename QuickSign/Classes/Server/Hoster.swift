//
//  Hoster.swift
//  QuickSign
//
//  Created by Constantin Clerc on 9/8/24.
//

import Telegraph
import Foundation

func setupAndDeploy() {
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    
    let server = Server()
    try! server.start(port: 9000)
    server.serveDirectory(URL(fileURLWithPath: "\(documentsPath)/temp"), "/tempWeb")
    server.route(.GET, "status") { (.ok, "Server is running") }
}
