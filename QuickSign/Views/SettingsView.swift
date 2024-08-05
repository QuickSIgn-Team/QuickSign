//
//  SettingsView.swift
//  QuickSign
//
//  Created by haxi0 on 05.08.2024.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section(content: {
                    Text("Placeholder")
                }, header: {
                    Image("Banner")
                        .resizable()
                        .scaledToFill()
                })
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SettingsView()
}
