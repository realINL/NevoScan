//
//  TermsOfUseView.swift
//  NevoScan
//
//  Created by Илья Лебедев on 11.05.2026.
//

import SwiftUI

struct TermsOfUseView: View {
    @Binding var termsAccepted: Bool
    @State private var showFullPolicy = false
    @State var terms: String = ""
    
    var body: some View {
        contentView
            .onAppear() {
                loadTermsOfUse()
            }
    }
    
    private var basicProvisions: some View {
        VStack {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 70))
                .foregroundStyle(.nevo)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    PolicyHighlightRow(
                        icon: "stethoscope",
                        title: "terms.highlight1.title",
                        description: "terms.highlight1.description"
                    )
                    PolicyHighlightRow(
                        icon: "iphone.and.arrow.forward",
                        title: "terms.highlight2.title",
                        description: "terms.highlight2.description"
                    )
                    
                    PolicyHighlightRow(
                        icon: "lock.fill",
                        title: "terms.highlight3.title",
                        description: "terms.highlight3.description"
                    )
                }
                .padding(.vertical, 8)
            } label: {
                Text("terms.basic_provisions")
            }
            .groupBoxStyle(.card)
        }
        
    }
    
    private var policyView: some View {
        VStack {
            Button {
                showFullPolicy.toggle()
            } label: {
                HStack {
                    Text("terms.terms")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(showFullPolicy ? 90 : 0))
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            if showFullPolicy {
                Text(terms)
                    .font(.footnote)
                    .padding()
            }
        }
    }
    
    var agreeView: some View {
        VStack(spacing: 12) {
            Button {
                DispatchQueue.main.async {
                    withAnimation {
                        termsAccepted = true
                    }
                }
                print("Set terms")
            } label: {
                Text("terms.agree")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(MainButtonStyle())
            .controlSize(.large)
            
            Text("terms.agree.disclaimer")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }
    
    var contentView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    basicProvisions
                    policyView
                }
            }
            .navigationTitle("terms.title")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                agreeView
            }
        }
    }
    
    private func loadTermsOfUse() {
        if let filePath = Bundle.main.path(forResource: "terms_of_use", ofType: "txt") {
            do {
                let content = try String(contentsOfFile: filePath, encoding: .utf8)
                terms = content
            } catch {
                
            }
        }
    }
}

#Preview {
    TermsOfUseView(termsAccepted: .constant(false))
}
