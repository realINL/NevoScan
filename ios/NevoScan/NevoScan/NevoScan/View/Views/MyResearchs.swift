//
//  MyResearchs.swift
//  NevoScan
//
//  Created by Илья Лебедев on 16.01.2026.
//

import SwiftUI
import SwiftData

struct MyResearchs: View {
    @Environment(\.modelContext) var context
    @Query private var researchs: [Research]
    var body: some View {
        VStack{
            Text("history.title")
                .font(.title2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
    
//                .headerProminence(.standard)
            if researchs.isEmpty {
                Spacer()
                Text("history.empty")
                    .font(.title)
                    .foregroundStyle(Color(.systemGray))
                Spacer()
            } else {
                List {
                    
                    ForEach(researchs.sorted(by: { $0.date >= $1.date})) { research in
                        NavigationLink(destination: MomentalResultView(research: research)) {
                            cardView(research)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .swipeActions {
                            Button("action.delete", systemImage: "trash", role: .destructive) {
                                context.delete(research)
                            }
                        }
                        
                    }
                    
                }
                .listStyle(.plain)
            }
        }
        .scrollContentBackground(.hidden)
        .header()
    }
    
    func cardView(_ research: Research) -> some View {
        HStack {
            Image(uiImage: research.originalImage ?? .dd)
                .resizable()
                .cornerRadius(12)
                .frame(width: 75, height: 58)
                .scaledToFill()
            Text("history.card.safety \(research.benignProbability.formatted(.roundedPercent))")
                .font(.body)
                .padding(.leading, 11)
        }
    }
    
    func delete(_ indexSet: IndexSet) {
        for i in indexSet {
            let research = researchs[i]
            context.delete(research)
        }
    }
}

#Preview {
    MyResearchs()
}
