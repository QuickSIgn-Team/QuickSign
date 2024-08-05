//
//  Signer.swift
//  QuickSign
//
//  Created by haxi0 on 05.08.2024.
//

import ZSign

class Signer {
    static let shared = Signer()
    
    func signIpa() {
        zsign("", "", "", "", "", "", "")
    }
}
