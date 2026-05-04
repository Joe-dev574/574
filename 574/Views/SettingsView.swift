//
//  SettingsView.swift
//  574
//

import SwiftUI

struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        Form {
            Section("Profile") {
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundStyle(.gray)
                    
                    Text("Joseph DeWeese")
                        .font(.title2.bold())
                }
                .frame(maxWidth: .infinity)
            }
            
            Section("Appearance") {
                Text("Theme controls coming soon")
            }
            
            Section("Data") {
                Button(role: .destructive) {
                    print("Clear all data")
                } label: {
                    Label("Clear All Data", systemImage: "trash.fill")
                }
            }
            
            Section("About") {
                Text("574 • Version 1.0")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

#Preview {
    SettingsView()
        .environment(ThemeManager())
}
