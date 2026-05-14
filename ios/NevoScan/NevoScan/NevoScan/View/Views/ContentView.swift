//
//  ContentView.swift
//  NevoScan
//
//  Created by Илья Лебедев on 16.01.2026.
//

import PhotosUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.container) private var container
    
    var body: some View {
        NavigationStack {
            contentView
        }
    }
    
    private var mainText: some View {
        Text("home.headline")
            .font(.title)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 60)
    }
    
    private var secondaryText: some View {
        Text("home.subtitle")
            .fontWeight(.light)
    }
    
    private var contentView: some View {
        VStack {
            
            Spacer()
            
            VStack(alignment: .leading) {
                mainText
                secondaryText
            }
            .frame(maxWidth: 250)
            
            Spacer()
            
            
            NavigationLink("action.start_analysis", destination: AnalyzeView(viewModel: container.createAnalyzeViewModel(modelContext)))
                .buttonStyle(MainButtonStyle())
            
            
            Spacer()
            Spacer()
            
            NavigationLink("home.my_analyses", destination: MyResearchs())
                .buttonStyle(MyResearchsButtonStyle())
        }
        .header()
    }
}

#Preview {
    ContentView()
}




