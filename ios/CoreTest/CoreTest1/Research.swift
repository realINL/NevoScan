//
//  MockModule.swift
//  NevoScan
//
//  Created by Илья Лебедев on 16.01.2026.
//

import Foundation
import SwiftUI
import SwiftData
import CoreML

//class MockModule {
//    private let detector: NevusYOLODetector?
//    private let segmenter: DeepLabSkinSegmenter?
//    private let classifier: ResNetFeatMaskClassifier?
//    private let hairRemoval = HairRemovalProcessor()
//
//    init() {
//        detector = try? NevusYOLODetector.loadBundled()
//        segmenter = try? DeepLabSkinSegmenter.loadBundled()
//        classifier = try? ResNetFeatMaskClassifier.loadBundled()
//    }
//
//    func predict(image: UIImage, completion: @escaping (Result<Research, Error>) -> Void) {
//        guard let detector else {
//            completion(.failure(NevusDetectionError.modelNotFound))
//            return
//        }
//        let segmenter = self.segmenter
//        let classifier = self.classifier
//        let hairRemoval = self.hairRemoval
//        Task.detached(priority: .userInitiated) {
//            do {
//                let (cropped, _) = try detector.cropNevus(from: image)
//                let hairRemoved = hairRemoval.process(cropped)
//
//                var mask256: MLMultiArray?
//                var segPreview: UIImage?
//                if let segmenter,
//                   let (m256, layout) = try? segmenter.predictBinaryMask256WithLetterboxLayout(from: hairRemoved) {
//                    mask256 = m256
//                    segPreview = try? segmenter.maskPreviewImage(fromBinaryMask256: m256, letterboxLayout: layout)
//                }
//
//                let benignProbability: Double
//                let malignProbability: Double
//                if let classifier, let mask256 {
//                    let probs: (benign: Double, malign: Double) =
//                        (try? classifier.probabilities(from: hairRemoved, mask256: mask256))
//                        ?? (benign: 0, malign: 0)
//                    benignProbability = probs.benign
//                    malignProbability = probs.malign
//                } else {
//                    benignProbability = 0
//                    malignProbability = 0
//                }
//
//                let research = Research(
//                    image: cropped,
//                    detectionScore: malignProbability,
//                    segmentationPreview: segPreview,
//                    hairRemovedImage: hairRemoved,
//                    benignProbability: benignProbability,
//                    malignProbability: malignProbability
//                )
//                await MainActor.run { completion(.success(research)) }
//            } catch {
//                await MainActor.run { completion(.failure(error)) }
//            }
//        }
//    }
//}

@Model
final class Research: Identifiable {
    var id: String
    var date: Date
    
    // Result
    var benignProbability: Double
    var malignProbability: Double
    
    // Images
    @Attribute(.externalStorage)
    var imageData: Data?
    @Attribute(.externalStorage)
    var croppedImageData: Data?
    @Attribute(.externalStorage)
    var segmentationImageData: Data?
    
    
    init(benignProbability: Double,
         malignProbability: Double,
         originalImage: UIImage? = nil,
         croppedImage: UIImage,
         segmentationImage: UIImage) {
        self.id = UUID().uuidString
        self.benignProbability = benignProbability
        self.malignProbability = malignProbability
        self.imageData = originalImage?.pngData() ?? nil 
        self.croppedImageData = croppedImage.pngData()
        self.segmentationImageData = segmentationImage.pngData()
        self.date = Date()
    }
    
    var originalImage: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }
    
    
    var segmentationImage: UIImage? {
        guard let segmentationImageData else { return nil }
        return UIImage(data: segmentationImageData)
    }
    
    var croppedImage: UIImage? {
        guard let croppedImageData else { return nil }
        return UIImage(data: croppedImageData)
    }
}

//extension Research {
//    /// Static research for previews
//    static let MOCK_RESEARCH = Research(benignProbability: 0.981213, malignProbability: 0.24521, originalImage: .test2, croppedImage: .test2, segmentationImage: .test2)
//}
