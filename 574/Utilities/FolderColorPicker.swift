//
//  FolderColorPicker.swift
//  574
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
                ForEach(Array(colors.enumerated()), id: \.offset) { _, item in
                    Button {
                        colorName = item.name
                    } label: {
                        ZStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 32, height: 32)
                                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                            
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
