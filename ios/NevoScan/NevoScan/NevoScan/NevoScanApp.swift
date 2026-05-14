//
//  NevoScanApp.swift
//  NevoScan
//
//  Created by Илья Лебедев on 16.01.2026.
//

import SwiftUI
import SwiftData
import UIKit
import YOLO
import PhotosUI
import CoreML
import Vision

@main
struct NevoScanApp: App {
    @AppStorage("termsOfUse") var terms: Bool = false
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Research.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    let container = DIContainer.shared
    
    var body: some Scene {
        WindowGroup {
            if terms {
                ContentView()
                    .environment(\.container, container)
            } else {
                TermsOfUseView(termsAccepted: $terms)
            }
               
        }
        .modelContainer(sharedModelContainer)
        
    }
}
