//
//  AnalyzeViewModel.swift
//  NevoScan
//
//  Created by Илья Лебедев on 14.04.2026.
//

import Foundation
import SwiftUI
import PhotosUI
import SwiftData

@MainActor
class AnalyzeViewModel: ObservableObject {
    private var modelContext: ModelContext
    // MARK: Images
    @Published var selectedItem: PhotosPickerItem? { didSet {handlePhotoSelection()} }
    @Published var cameraImage: UIImage? { didSet {handleCameraPhotoSelection()}}
    @Published var selectedImage: UIImage?
    private var imageWithDetection: UIImage?
    private var croppedImage: UIImage?
    
    // MARK: View
    @Published var presentInstructions: Bool = true
    @Published var isLoading: Bool = false
    @Published var isDone: Bool = false
    @Published var presentCamera: Bool = false
    
    
    // MARK: Error handling
    @Published var showAlert: Bool = false
    @Published var alertText: Error?
    
    // MARK: Research
    @Published var researchId: String?
    
    
    let engine: CoreEngine
    
    init(modelContext: ModelContext, engine: CoreEngine) {
        self.modelContext = modelContext
        self.engine = engine
        
    }
    
    func setModelContext(_ modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    @MainActor
    func detect(on image: UIImage) {
        Task {
            do {
                let detection = try await engine.detect(on: image)
                DispatchQueue.main.async {
                    withAnimation {
                        self.presentInstructions = false
                        self.croppedImage = detection.cropedImage
                        self.selectedImage = detection.detectedImage
                        print("detection ok")
                    }
                }
            } catch {
                alertText = error
                showAlert = true
                self.selectedItem = nil
                print(error.localizedDescription)
            }
        }
        
    }
    
    private func handlePhotoSelection() {
        Task {
            if let loaded = try? await selectedItem?.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: loaded) {
                    self.selectedImage = uiImage
                    detect(on: uiImage)
                } else {
                    print("No image selected")
                }
            } else {
                print("No item selected")
            }
        }
    }
    
    private func mochHandle() {
        Task {
            if let loaded = try? await selectedItem?.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: loaded) {
                    self.selectedImage = uiImage
//                    detect(on: uiImage)
                } else {
                    print("No image selected")
                }
            } else {
                print("No item selected")
            }
        }
    }
    
    /// Handling selecting photo from camera
    private func handleCameraPhotoSelection() {
        guard let cameraImage else { print("no camera image"); return }
        self.selectedImage = cameraImage
        detect(on: cameraImage)
    }
    
    func resetSelectedImage() {
        self.selectedItem = nil
        self.selectedImage = nil
        self.croppedImage = nil
        self.presentInstructions = true
    }
    
    func analyze() {
        guard let croppedImage else {
            self.alertText = AnalyzeErrors.noImage
            self.showAlert = true
            self.isLoading = false
            return
        }
        
        
        Task(priority: .userInitiated) {
            do {
                self.isLoading = true
                let result = try await self.engine.predict(on: croppedImage)
                result.imageData = selectedImage?.pngData()
                saveResearch(research: result)
                self.researchId = result.id
                isLoading = false
                selectedItem = nil
                selectedImage = nil
                isDone = true
            } catch {
                self.alertText = error
                self.showAlert = true
                self.isLoading = false
            }
        }
    }
    
    func lResearch() throws ->  Research {
        guard let researchId else { throw AnalyzeErrors.noImage }
        guard let research = loadResearch(id: researchId) else { throw AnalyzeErrors.noImage }
        return research
    }
    
    // MARK: Swift data functions
    /// Save research
    private func saveResearch(research: Research) {
        do {
            modelContext.insert(research)
            try modelContext.save()
        } catch {
            print("Saving error")
        }
    }
    
    /// Load saved research
    private func loadResearch(id: String) -> Research? {
        var research: [Research]?
        let descriptor = FetchDescriptor<Research>(
            predicate: #Predicate {$0.id == id}
        )
        do {
            research = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetchng: \(error.localizedDescription)")
        }
        return research?.first
    }
}

enum AnalyzeErrors: LocalizedError {
    case noImage
    case noContext
    
    var errorDescription: String? {
        switch self {
        case .noImage:
            return "No image selected"
        case .noContext:
            return "Database context is not configured"
        }
    }
}
