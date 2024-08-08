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
        .onAppear {
            // Big thanks to this comment on Reddit https://www.reddit.com/r/SwiftUI/comments/p8obef/comment/hdqjc0a/
            let tabBarAppearance = UITabBarAppearance()
            let navigationBarAppearance = UINavigationBarAppearance()
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
        }
    }
}

#Preview {
    ContentView()
}
