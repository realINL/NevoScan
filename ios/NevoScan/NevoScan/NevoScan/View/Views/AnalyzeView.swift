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
        .alert("error.processing",
               isPresented: $viewModel.showAlert,
               presenting: viewModel.alertText) {
            details in
            Button("action.ok", role: .cancel) { }
            
        } message: { details in
            Text(LocalizedStringKey(stringLiteral: details.localizedDescription))
        }
        
    }
    
    // MARK: Instruction header View
    private var instructionHeaderView: some View {
        HStack {
            Group {
                Text("analyze.recommendations")
                Image(systemName: "chevron.down")
                    .rotationEffect(.degrees(viewModel.presentInstructions ? 0 : -90))
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
            
            Text("analyze.pick_source")
                .padding(38)
            
            PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                Text("analyze.photo_library")
            }
            .buttonStyle(InputButtonStyle())
            .padding(.bottom, 19)
            
            Button("analyze.camera") {
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
                Button("action.reset") {
                    withAnimation {
                        viewModel.resetSelectedImage()
                    }
                }
                .buttonStyle(ResetButtonStyle())
                
                Button("action.start_analysis") {
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
                Text("analyze.loading")
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


