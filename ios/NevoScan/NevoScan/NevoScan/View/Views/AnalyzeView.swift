//
//  AnalyzeView.swift
//  NevoScan
//
//  Created by Илья Лебедев on 14.04.2026.
//

import SwiftUI
import PhotosUI
struct AnalyzeView: View {
    
    @StateObject var viewModel: AnalyzeViewModel
    @Environment(\.modelContext) private var modelContext
    
    init(viewModel: AnalyzeViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        contentView
            .header()
            .sheet(isPresented: $viewModel.isDone) {
                try? MomentalResultView(research: viewModel.lResearch())
            }
            .sheet(isPresented: $viewModel.presentCamera) {
                CameraView(image: $viewModel.cameraImage)
            }
    }
    
    private var contentView: some View {
        VStack {
            
            if !viewModel.isLoading { instructionHeaderView
                if viewModel.presentInstructions {
                    instrctionsView
                }
            }
            
            Spacer()
            
            if viewModel.selectedImage != nil {
                imagecontrol(image: $viewModel.selectedImage)
            } else {
                photoPickerView
            }
            
            Spacer()
        }
        .alert("Ошибка обработки",
               isPresented: $viewModel.showAlert,
               presenting: viewModel.alertText) {
            details in
            Button("Ok", role: .cancel) { }
            
        } message: { details in
            Text(details.localizedDescription)
        }
        
    }
    
    // MARK: Instruction header View
    private var instructionHeaderView: some View {
        HStack {
            Group {
                Text("Рекомендации")
                Image(systemName: viewModel.presentInstructions ? "chevron.up" : "chevron.down")
                    .onTapGesture {
                        withAnimation {
                            viewModel.presentInstructions.toggle()
                        }
                    }
            }
            .font(.title)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: Instructions list View
    private var instrctionsView: some View {
        ForEach(Instruction.Instruction_MOCK_UP, id: \.point) { instruction in
            InstructionCardView(instruction: instruction)
        }
    }
    
    // MARK: Photo pickers view
    /// Display photo picker sources
    private var photoPickerView: some View {
        VStack {
            
            Text("Выберите источник для загрузки фото")
                .padding(38)
            
            PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                Text("Медиатека")
            }
            .buttonStyle(InputButtonStyle())
            .padding(.bottom, 19)
            
            Button("Камера") {
                viewModel.presentCamera = true
            }
            .buttonStyle(InputButtonStyle())
            
            Spacer()
        }
    }
    
    // MARK: Selected image view
    /// Display selected image or loading view
    private func selectedImageView(image: UIImage) -> some View {
        
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(25)
            .frame(maxWidth: 300)
    }
    
    
    // MARK: Selected image control view
    /// Display selected image and controls
    private func imagecontrol(image: Binding<UIImage?>) -> some View {
        VStack {
            if let image = image.wrappedValue {
                selectedImageView(image: image)
                    .padding(.vertical, 40)
            }
            
            if !viewModel.isLoading {
                Button("Сбросить") {
                    withAnimation {
                        viewModel.resetSelectedImage()
                    }
                }
                .buttonStyle(ResetButtonStyle())
                
                Button("Начать анализ") {
                    withAnimation {
                        viewModel.analyze()
                    }
                }
                .buttonStyle(InputButtonStyle())
                .disabled(viewModel.selectedImage == nil)
            } else {
                ProgressView()
                    .scaleEffect(2.0)
                    .padding(.top, 62)
                Text("Анализируем ваше фото")
                    .padding(.vertical, 26)
                
            }
        }
    }
    
    private func handlePhotoSelection() {
        Task {
            if let loaded = try? await viewModel.selectedItem?.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: loaded) {
                    viewModel.selectedImage = uiImage
                    withAnimation {
                        viewModel.presentInstructions = false
                    }
                } else {
                    print("Failed")
                }
            } else {
                print("Failed")
            }
        }
    }
    
    
    
}

//#Preview {
//    AnalyzeView(viewModel: AnalyzeViewModel(modelContext: ))
//        .modelContainer(for: Research.self, inMemory: true)
//}
