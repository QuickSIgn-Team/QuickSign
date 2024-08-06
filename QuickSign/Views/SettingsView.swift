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
                    NavigationLink(destination: AppIconView()) {
                        Text("App Icons")
                    }
                }, header: {
                    Image("Banner")
                        .resizable()
                        .scaledToFill()
                })
                Section(content: {
                    HStack(alignment: .center) {
                        Image("DefaultIcon")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text("Someone")
                                .font(.headline)
                            Text("placeholder")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            openWebsite(urlString: "https://www.example.com")
                        }) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {}
                }, header: {
                    Text("credits")
                })
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Function to open a website
    func openWebsite(urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
}
