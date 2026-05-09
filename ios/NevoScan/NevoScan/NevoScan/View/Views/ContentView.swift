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
//    @State private var nevusItem: PhotosPickerItem?
//    @State var nevusImage: UIImage?
//    @State var showResult = false
//    @State var currentResearch: Research?
//    @State var isLoaading = false
//    @State var presentCamera = false
//    @State var showInstruction = false

    var body: some View {
        NavigationStack {
            contentView

            //                            Button("Show Camera") {
            //                                presentCamera = true
            //                            }
            //                            .foregroundStyle(.ac)
            //                        }
            //
            //
            //                    } else {
            //                        if let image = nevusImage {
            //                            VStack {
            //                                Image(uiImage: image)
            //                                    .resizable()
            //                                    .frame(width: 150, height: 150)
            //                                    .clipShape(.circle)
            //                                Button("Начать анализ") {
            //                                    isLoaading = true
            //                                    engine.predict(image: image, completion: loadResult)
            //                                }
            //                                if isLoaading {
            //                                    ProgressView()
            //                                        .frame(maxHeight: 50)
            //                                }
            //
            //
            //                            }
            //                            .buttonStyle(.borderedProminent)
            //                            .disabled(isLoaading)
            //
            //                        }
            //                    }
            //                }
            //
            //                Spacer()
            //                NavigationLink("Мои исследования", destination: MyResearchs())
            ////                    .foregroundStyle(.ac)
            //                .buttonStyle(.borderedProminent)
            ////                    .background(.ac)
            //
            //            }
            //            .frame(maxWidth: .infinity, maxHeight: .infinity)
            //            .background(Color.nevoGray)
            //
            //        }
            //
            //
            //
            //        .onChange(of: nevusItem) {
            //            Task {
            //                if let loaded = try? await nevusItem?.loadTransferable(type: Data.self) {
            //                    if let uiImage = UIImage(data: loaded) {
            //                        nevusImage = uiImage
            //                    } else {
            //                        print("Failed")
            //                    }
            //                } else {
            //                    print("Failed")
            //                }
            //            }
            //
            //        }
            //        .sheet(isPresented: $presentCamera) {
            //            ImagePicker(image: $nevusImage)
            //        }        .popover(isPresented: $showResult) {
            //            if let research = currentResearch {
            //                ResearchView(research: research )
            //            } else {
            //                Text("No data")
            //            }
            //        }
        }
//        .sheet(isPresented: $showInstruction) {
//            HStack {
//                Text("Анализ родинки")
//                    .font(.title)
//                    .fontWeight(.medium)
//            }
//            .padding(.vertical)
//
//                            .presentationDragIndicator(.visible)
//        }

    }
    
    private var mainText: some View {
        Text("Проверьте свою\nродинку")
            .font(.title)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 60)
    }
    
    private var secondaryText: some View {
        Text(
            "Загрузите фото своей родинки и узнайте о ней подробнее"
        )
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
            
            
            NavigationLink("Начать анализ", destination: AnalyzeView(viewModel: container.createAnalyzeViewModel(modelContext)))
            .buttonStyle(MainButtonStyle())
            

            Spacer()
            Spacer()

            NavigationLink("Мои исследования", destination: MyResearchs())
                .buttonStyle(MyResearchsButtonStyle())
        }
        .header()
    }

//    private func loadResult(_ research: Research) {
//        print(research.score)
//        currentResearch = research
//        isLoaading = false
//        showResult = true
//        addItem()
//        //        nevusItem = nil
//        //        nevusImage = nil
//    }

}

#Preview {
    ContentView()
}




