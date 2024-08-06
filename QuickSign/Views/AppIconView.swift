//
//  AppIconView.swift
//  QuickSign
//
//  Created by Salupov Tech on 8/6/24.
//

import SwiftUI

struct Icon: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let image: String
}

struct AppIconView: View {
    let icons = [
        Icon(title: "Standart", icon: "AppIcon", image: "AppIconImage"),
        Icon(title: "Picasso", icon: "Picasso", image: "PicassoImage"),
        Icon(title: "Scarlet", icon: "Scarlet", image: "ScarletImage"),
        Icon(title: "ESign", icon: "ChineseSign", image: "ChineseSignImage"),
        Icon(title: "GBox", icon: "BoxSign", image: "BoxSignImage"),
        Icon(title: "AltStore", icon: "AltSign", image: "AltSignImage"),
        Icon(title: "BRAT", icon: "BratSign", image: "BratSignImage"),
        Icon(title: "Paint", icon: "ScuffedSign", image: "ScuffedSignImage")
    ]
    
    var body: some View {
        NavigationView {
            List(icons) { icon in
                Button(action: {
                    changeAppIcon(to: icon.icon)
                }) {
                    HStack {
                        Image(icon.image)
                            .resizable()
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                            .padding(.trailing, 8)
                        Text(icon.title)
                            .font(.system(size: 18, weight: .medium))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    func changeAppIcon(to iconName: String) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("Alternate icons are not supported.")
            return
        }
        
        UIApplication.shared.setAlternateIconName(iconName == "AppIcon" ? nil : iconName) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            } else {
                print("App icon changed to \(iconName).")
            }
        }
    }
}

#Preview {
    AppIconView()
}
