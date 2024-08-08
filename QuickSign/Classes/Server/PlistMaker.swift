//
//  PlistMaker.swift
//  QuickSign
//
//  Created by Constantin Clerc on 9/8/24.
//

import Foundation

func generatePlist(bundleID: String, name: String, version: String) -> Data? {
    let urlFrServer = "http://localhost:9000/tempWeb" //im lazy sorry haxi
    let plist: [String: Any] = [
        "items": [
            [
                "assets": [
                    [
                        "kind": "software-package",
                        "url": "\(urlFrServer)/pck.ipa"
                    ],
                    [
                        "kind": "display-image",
                        "url": "\(urlFrServer)/pck.png"
                    ],
                    [
                        "kind": "full-size-image",
                        "url": "\(urlFrServer)/pckf.png"
                    ]
                ],
                "metadata": [
                    "bundle-identifier": bundleID,
                    "bundle-version": version,
                    "kind": "software",
                    "title": name
                ]
            ]
        ]
    ]
    
    do {
        let plistData = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        print("plist data incomming !!!!! \n \(plistData)")
        return plistData
    } catch {
        print("\(error)")
        return nil
    }
}
