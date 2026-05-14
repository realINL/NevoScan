//
//  ResearchView.swift
//  NevoScan
//
//  Created by Илья Лебедев on 16.01.2026.
//

import SwiftUI

//struct ResearchView: View {
//    let research: Research
//    var body: some View {
//        List {
//            Section("Дата анализа") {
//                Text(research.date.formatted(date: .abbreviated, time: .shortened))
//            }
//            if let image = research.originalImage {
//                Section("Фото") {
//                    Image(uiImage: image)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(maxHeight: 250)
//                }
//            }
//            if let seg = research.segmentationImage {
//                Section("Сегментация (временно)") {
//                    Image(uiImage: seg)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(maxHeight: 280)
//                }
//            }
//            if let hairRemoved = research.croppedImage {
//                Section("После удаления волос") {
//                    Image(uiImage: hairRemoved)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(maxHeight: 250)
//                }
//            }
//            Section("Результат") {
//                labledSectionRow(label: "Benign", value: research.benignProbability.formatted(.percent))
//                labledSectionRow(label: "Malign", value: research.malignProbability.formatted(.percent))
//                Text(Recomendation.getRecommendation(for: research.malignProbability))
//            }
//
//        }
//        .scrollContentBackground(.hidden)
////        .background(Color.ac)
//    }
//}


enum Recomendation {
    static func getRecommendation(for score: Double) -> String {
        switch score {
        case 0..<0.3: return "Здоровая родинка"
        case 0.3..<0.7: return "Стоит показать врачу"
        default: return "Срочно обратитесь к врачу"
        }
    }
}

//struct labledSectionRow: View {
//    let label: String
//    let value: String
//
//    var body: some View {
//        HStack {
//            Text(label)
//            Spacer()
//            Text(value)
//                .foregroundStyle(.secondary)
//
//        }
//    }
//}

struct MomentalResultView: View {
    let research: Research
    
    var body: some View {
        contentView
        //            .header()
        
        //        VStack {
        //            if let image = research.originalImage {
        //                Image(uiImage: image)
        //                    .resizable()
        //                    .aspectRatio(contentMode: .fit)
        //                    .frame(maxWidth: 300, maxHeight: 400)
        //                    .cornerRadius(20)
        //            }
        //            if let seg = research.segmentationImage {
        //                Text("Сегментация (временно)")
        //                    .font(.headline)
        //                    .padding(.top, 8)
        //                Image(uiImage: seg)
        //                    .resizable()
        //                    .interpolation(.none)
        //                    .aspectRatio(contentMode: .fit)
        //                    .frame(maxWidth: 300, maxHeight: 300)
        //                    .cornerRadius(12)
        //            }
        //            Text("Результат:")
        //                .font(.title)
        //                .padding(.vertical, 32)
        //
        //            VStack(spacing: 8) {
        //                Text("Benign: \(research.benignProbability?.formatted(.percent))")
        //                    .font(.title3)
        //                Text("Malign: \(research.malignProbability?.formatted(.percent))")
        //                    .font(.title3)
        //            }
        //            Text(Recomendation.getRecommendation(for: research.malignProbability ?? 0.0))
        //                .font(.title2)
        //
        //            Label("Не является диагнозом", systemImage: "exclamationmark.triangle.fill")
        //                .padding()
        //                .background(Color.yellow.opacity(0.35))
        //                .cornerRadius(20)
        //                .padding(.vertical, 32)
        //        }
    }
    
    private var contentView: some View {
        VStack {
            
            header
            originalImageView
            probsView
            processImages
            disclaimer
            
            
        }
        .header()
        
    }
    
    // MARK: Header View
    private var header: some View {
        VStack(spacing: 16) {
            Text("result.title")
                .font(.title)
            Text(research.date.formatted(date: .long, time: .shortened))
                .font(.subheadline)
        }
        .padding(.bottom, 54)
    }
    
    // MARK: Original image with detection view
    private var originalImageView: some View {
        Image(uiImage: research.originalImage ?? .vtw)
            .resizable()
            .scaledToFit()
            .cornerRadius(25)
            .padding(.horizontal, 31)
            .padding(.bottom, 24)
        
        
    }
    
    // MARK: Probabilities view
    ///  View contains probaility of benign and malign
    private var probsView: some View {
        let compare = research.benignProbability > research.malignProbability
        return VStack(spacing: 14) {
            Group {
                if compare {
                    Text("result.prob.benign \(research.benignProbability.formatted(.roundedPercent))")
                        .font(.headline)
                    
                    Text("result.prob.malign \(research.malignProbability.formatted(.roundedPercent))")
                        .font(.subheadline)
                } else {
                    Text("result.prob.malign \(research.malignProbability.formatted(.roundedPercent))")
                        .font(.headline)
                    
                    Text("result.prob.benign \(research.benignProbability.formatted(.roundedPercent))")
                        .font(.subheadline)
                }
            }
//            .font(.callout)
        }
        .padding(.bottom, 62)
    }
    
    // MARK: Process images view
    /// View contains images reciedev in research
    private var processImages: some View {
        VStack(spacing: 22) {
            Text("result.process")
                .font(.callout)
            
            HStack(spacing: 13) {
                processImage(image: research.croppedImage ?? .dd, phase: .crop)
                processImage(image: research.segmentationImage ?? .dd, phase: .segment)
            }
            .padding(.horizontal, 31)
        }
    }
    
    // MARK: Process image view
    /// Single image reciedev in research
    private func processImage(image: UIImage, phase: ResearchPhases) -> some View {
        VStack(alignment: .leading) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .fixedSize(horizontal: false, vertical: true)
                .cornerRadius(25)
                .padding(.bottom, 13)
            
            Text(phase.rawValue)
                .font(.footnote)
        }
    }
    
    // MARK: Disclaimer
    private var disclaimer: some View {
        Label("result.disclaimer", systemImage: "exclamationmark.triangle.fill")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.yellow.opacity(0.35))
            .cornerRadius(20)
            .padding(.horizontal, 62)
            .padding(.top, 15)
    }
    
}

// MARK: Phases of research
enum ResearchPhases: LocalizedStringKey {
    case crop = "result.phase.crop"
    case segment = "result.phase.mask"
}
#Preview {
    MomentalResultView(research: Research.MOCK_RESEARCH)
}




extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Percent {
    
    /// Percent format with 0 signs
    public static var roundedPercent: FloatingPointFormatStyle<Double>.Percent {
        return
            .percent
            .precision(.fractionLength(0))
    }
}
