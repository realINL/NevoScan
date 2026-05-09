//
//  ViewModifiers.swift
//  NevoScan
//
//  Created by Илья Лебедев on 16.04.2026.
//

import SwiftUI

struct NevoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(configuration.isPressed ? Color.nevo.opacity(0.7) : Color.nevo)
            .foregroundColor(.white)
            .cornerRadius(18)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct InputButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .padding()
            .frame(width: CGFloat(0.522).toWidth(), height: CGFloat(0.064).toHeight())
            .background(configuration.isPressed ? Color.nevo.opacity(0.7) : Color.nevo)
            .foregroundColor(.white)
            .cornerRadius(31)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .transition(.opacity)
    }
}

struct ResetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .padding()
            .frame(width: 210, height: 57)
            .background(configuration.isPressed ? Color(.systemGray6).opacity(0.7) : Color(.systemGray6))
            .foregroundColor(.black)
            .cornerRadius(31)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
            .padding(.bottom, 19)
            .transition(.opacity)
    }
}

struct MyResearchsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.light)
    }
}

struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        
        configuration.label
            .fontWeight(.medium)
            .padding(.horizontal, 33)
            .padding(.vertical, 24)
            .frame(width: .FWidth(253), height: .FHeight(76.8))
            .background(Color.nevo)
            .cornerRadius(34)
            .foregroundStyle(.white)
    }
}
