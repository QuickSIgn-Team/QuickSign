//
//  ContentView.swift
//  QuickSign
//
//  Created by haxi0 on 05.08.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ApplicationView()
                .tabItem {
                    Label("Apps", systemImage: "square.stack.3d.up.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
