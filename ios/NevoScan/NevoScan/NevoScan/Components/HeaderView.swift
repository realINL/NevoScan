//
//  AppLogo.swift
//  NevoScan
//
//  Created by Илья Лебедев on 14.04.2026.
//

import Foundation
import SwiftUI

// MARK: Header View
struct HeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    headerView
                }
            }
    }
    
    private var headerView: some View {
            Text("app.name")
                .bold()
                .foregroundStyle(.nevo)
        }
}

extension View {
    func header() -> some View {
        modifier(HeaderModifier())
    }
}

