//
//  CustomTextFieldStyle.swift
//  PolyPal
//
//  Created on 2025-07-22.
//

import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .padding(.horizontal, 16)
      .padding(.vertical, 16)
      .background {
        #if canImport(UIKit)
        Color(.systemGray6)
        #elseif canImport(AppKit)
        Color(.quaternaryLabelColor)
        #else
        Color.gray.opacity(0.1)
        #endif
      }
      .cornerRadius(12)
      .font(.system(size: 16, weight: .regular))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke({
            #if canImport(UIKit)
            Color(.systemGray4)
            #elseif canImport(AppKit)
            Color(.tertiaryLabelColor)
            #else
            Color.gray.opacity(0.3)
            #endif
          }(), lineWidth: 1)
      )
  }
}
