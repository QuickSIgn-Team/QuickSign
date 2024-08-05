//
//  ApplicationView.swift
//  QuickSign
//
//  Created by haxi0 on 05.08.2024.
//

import SwiftUI

struct ApplicationView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    appSection()
                    appSection()
                    appSection()
                }
            }
            .navigationTitle("QuickSign")
            .navigationBarTitleDisplayMode(.inline)
        }
        
    }
    
    private func appSection() -> some View {
        HStack {
            Image("DefaultIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white, lineWidth: 0.5)
                        .opacity(0.3)
                )
            
            VStack(alignment: .leading, spacing: 1) {
                Text("App Placeholder")
                    .bold()
                    .font(.system(size: 16))
                Text("69.0 • App Size")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                // Placeholder
            }) {
                Text("Sign")
                    .bold()
                    .frame(width: 58 , height: 20, alignment: .center)
            }
            .buttonStyle(.bordered)
            .cornerRadius(20)
        }
    }
}

#Preview {
    ApplicationView()
}
