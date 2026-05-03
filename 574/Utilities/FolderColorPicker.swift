//
//  FolderColorPicker.swift
//  574
//
//  Created by Joseph DeWeese on 5/3/26.
//
//  PRODUCTION Reusable Professional Folder Color Picker.
//  Horizontal circular swatches with selection indicator — Apple HIG style.
//

import SwiftUI

struct FolderColorPicker: View {
    @Binding var colorName: String?
    
    private let colors: [(name: String?, color: Color, label: String)] = [
        (nil,      .primary,       "Default"),
        ("blue",   .blue,         "Blue"),
        ("red",    .red,          "Red"),
        ("green",  .green,        "Green"),
        ("orange", .orange,       "Orange"),
        ("purple", .purple,       "Purple"),
        ("yellow", .yellow,       "Yellow")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(colors, id: \.name) { item in
                    Button {
                        colorName = item.name
                    } label: {
                        ZStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 32, height: 32)
                                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                            
                            // Selection indicator
                            if colorName == item.name {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 3)
                                    .frame(width: 32, height: 32)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .accessibilityLabel(item.label)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }
}
