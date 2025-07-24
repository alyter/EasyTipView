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
      .background(Color(.systemGray6))
      .cornerRadius(12)
      .font(.system(size: 16, weight: .regular))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color(.systemGray4), lineWidth: 1)
      )
  }
}
