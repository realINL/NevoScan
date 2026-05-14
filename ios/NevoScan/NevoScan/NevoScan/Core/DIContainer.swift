//
//  DICinteiner.swift
//  NevoScan
//
//  Created by Илья Лебедев on 14.04.2026.
//

import SwiftUI
import SwiftData

class DIContainer {
    static let shared = DIContainer()
    
    let engine: EngineProtocol
    
    private init() {
        do {
            self.engine = try CoreEngine()
        } catch {
            fatalError("Core engine loading failed")
        }
    }
    
    @MainActor
    func createAnalyzeViewModel(_ modelContext: ModelContext) -> AnalyzeViewModel {
        return AnalyzeViewModel(modelContext: modelContext, engine: engine)
    }
}


// MARK: Environment exstensions

struct DIContainerKey: EnvironmentKey {
    static let defaultValue = DIContainer.shared
}

extension EnvironmentValues {
    var container: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}


