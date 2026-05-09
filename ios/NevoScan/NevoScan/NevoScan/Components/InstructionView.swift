//
//  InstructionView.swift
//  NevoScan
//
//  Created by Илья Лебедев on 16.01.2026.
//

import SwiftUI
import PhotosUI

struct Instruction {
    let point: Int
    let title: String
    let description: String
    let image: UIImage
}

//struct InstructionView: View {
//    @Environment(\.modelContext) private var modelContext
//    @State private var nevusItem: PhotosPickerItem?
//    @State var nevusImage: UIImage?
//    @State var showResult = false
//    @State var currentResearch: Research?
//    @State var isLoaading = false
//    @State var presentCamera = false
//    @State var presentInstructions = true
//    @State private var showDetectionAlert = false
//    @State private var detectionAlertMessage = ""
//    @State private var h = CGFloat(400)
//
//    let coef = 0.91
//
//    let engine = MockModule()
//    
//    var body: some View {
//
//        VStack {
//            HStack {
//                Group {
//                    Text("Рекомендации")
//                    Image(systemName: presentInstructions ? "chevron.up" : "chevron.down")
//                        .onTapGesture {
//                            withAnimation {
//                                presentInstructions.toggle()
//                                h = presentInstructions ? 400 : 0
//                            }
//                        }
//                }
//                .font(.title)
//                Spacer()
//                
//            }
//            .padding(.horizontal, 32)
//            
////            Rectangle()
////                .fill(.blue)
////                .frame(width: 200, height: h)
////                .padding()
//            
////            if currentResearch == nil {
//            if presentInstructions {
////            VStack() {
//                ForEach(Instruction.Instruction_MOCK_UP, id: \.point) { instruction in
//                    InstructionCardView(instruction: instruction)
//                }
//                //            }
////                .transition(.move(edge: .top).combined(with: .opacity))
//            }
////            .frame(height: h)
////            .clipped()
////            .background(.gray)
//            Spacer()
//                
//                if let image = nevusImage {
//                    VStack {
//                        ZStack {
//                            
//                            Image(uiImage: image)
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(maxWidth: 300, maxHeight: 400)
//                                .cornerRadius(20)
//                                .opacity(isLoaading ? 0.6 : 1)
//                            if isLoaading {
//                                ProgressView()
//                            }
//                            //                            .clipShape(.rect)
//                        }
//                        
//                        Button("Сбросить") {
//                            nevusImage = nil
//                            nevusItem = nil
//                            withAnimation {
//                                presentInstructions = true
//                            }
//                        }
//                        .buttonStyle(ResetButtonStyle())
//                        
//                        Button("Начать анализ") {
//                            isLoaading = true
//                            engine.predict(image: image, completion: handlePredictionResult)
//                        }
//                        .buttonStyle(InputButtonStyle())
//                       
//                        
//                        
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .disabled(isLoaading)
//                    
//                } else {
//                    HStack {
//                        Text("Выберите фото")
//                            .font(.title)
//                        Spacer()
//                    }
//                    .padding(32)
//                    
//                    PhotosPicker(selection: $nevusItem, matching: .images) {
//                        Text("Медиатека")
//                    }
//                    .buttonStyle(InputButtonStyle())
//                    .padding(.bottom, 19)
//                    
//                    Button("Камера") {
//                        presentCamera = true
//                    }
//                    .buttonStyle(InputButtonStyle())
//                }
//            Spacer()
////            }
////            else {
////                if let research = currentResearch {
////                    ResearchView(research: research)
////                } else {
////                    Text("No data")
////                }
////            }
//        }
//        
//            
//        .navigationTitle("Анализ")
//            .onChange(of: nevusItem) {
//                Task {
//                    if let loaded = try? await nevusItem?.loadTransferable(type: Data.self) {
//                        if let uiImage = UIImage(data: loaded) {
//                            nevusImage = uiImage
//                            withAnimation {
//                                presentInstructions = false
//                                h = presentInstructions ? 400 : 0
//                            }
//                        } else {
//                            print("Failed")
//                        }
//                    } else {
//                        print("Failed")
//                    }
//                }
//                
//            }
//            .sheet(isPresented: $presentCamera) {
//                ImagePicker(image: $nevusImage)
//            }
//            .popover(isPresented: $showResult) {
//                if let research = currentResearch {
//                    MomentalResultView(research: research )
//                } else {
//                    Text("No data")
//                }
//
//        }
//        .alert("Анализ", isPresented: $showDetectionAlert) {
//            Button("OK", role: .cancel) {}
//        } message: {
//            Text(detectionAlertMessage)
//        }
//    }
//
//    private func handlePredictionResult(_ result: Result<Research, Error>) {
//        switch result {
//        case .success(let research):
//            currentResearch = research
//            isLoaading = false
//            showResult = true
//            addItem()
//        case .failure(let error):
//            isLoaading = false
//            detectionAlertMessage = error.localizedDescription
//            showDetectionAlert = true
//        }
//    }
//    
//        private func addItem() {
//            if let research = currentResearch {
//                do {
//                    modelContext.insert(research)
//                    try modelContext.save()
//                    
//                } catch {
//                    print("Error saving")
//                }
//            }
//        }
//    
//}


struct InstructionCardView: View {
    let instruction: Instruction
    let coef = 0.91
    
    var body: some View {
        HStack() {
            Image(uiImage: instruction.image)
                .resizable()
                .frame(width: .FHeight(120), height: .FHeight(120))
                .cornerRadius(20)
            
            Spacer(minLength: 14 * coef)
            
            VStack(alignment: .leading) {
                Text("\(instruction.point). \(instruction.title)")
                    .font(.callout)
                    .fontWeight(.semibold)
                Text(instruction.description)
                    .font(.caption)
//                    .fontWeight(.light)
            }
            .frame(maxWidth: 240 * coef)
        }
        .padding(.leading, 32 * coef)
        .padding(.trailing, 24 * coef)
        .padding(.vertical, 5 * coef)
    }
}

//#Preview {
//    InstructionView()
//}

extension Instruction {
    static let Instruction_MOCK_UP = [
        Instruction(point: 1, title: "Четкая фокусировка", description: "Сфотографируйте родинку с расстояния 10-15 см, используя макрорежим или зум. Избегайте размытых снимков", image: .i1),
        Instruction(point: 2, title: "Освещение", description: "Родинка должна быть хорошо освещена, чтобы были видны границы, текстура и цвет. Лучше всего использовать естественный дневной свет", image: .i2),
        Instruction(point: 3, title: "Ничего лишнего", description: "Родинка должна быть полностью видна. На снимке не должно быть волос, закрывающих родинку, одежды или косметики", image: .i3)
    ]
}



