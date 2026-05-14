//
//  CoreEngine.swift
//  NevoScan
//
//  Created by Илья Лебедев on 14.03.2026.
//

import Foundation
import YOLO
import UIKit
import CoreML

// MARK: CoreEngine class
/// Class for core engine of analysis
class CoreEngine: EngineProtocol {
    private let detector: DetectorProtocol
    private let segmenter: SegmenterProtocol
    private let classifier: ClassifierProtocol
    
    init() throws {
        self.detector = Detector2()
        self.segmenter = try SegmenterImageType()
        self.classifier = try Classifier()
    }
    
    func detect(on image: UIImage) async throws -> (cropedImage: UIImage,
                                                    detectedImage: UIImage) {
        let result = try self.detector.detectMole(on: image)
        
        return (result.crop, result.annotaion)
        
    }
    
    // MARK: Segmentation function
    /// Function for segmentation image
    private func segment(image: UIImage) async throws -> (mask: UIImage, maskArray: MLMultiArray) {
        let result = try await segmenter.runSegmentation(on: image)
        return (result.maskResult, result.maskArray)
    }
    
    // MARK: Classification function
    /// Function for classification image. Returns benign and malign probabilities
    private func classify(image: UIImage, mask: MLMultiArray) throws -> (benign: Double, malign: Double) {
        do {
            let classificationResult = try classifier.probabilities(image: image, mask: mask)
            let benign = classificationResult.benign
            let malign = classificationResult.malign
            return (benign, malign)
        } catch {
            throw CoreEngineErrors.classificationError
        }
        
    }
    
    // MARK: Predict function
    /// Main function for mole analysis. Returns research result
    func predict(on image: UIImage) async throws -> Research {
        let segmentation = try await self.segment(image: image)
        let classification = try self.classify(image: image, mask: segmentation.maskArray)
        
        let result = Research(benignProbability: classification.benign, malignProbability: classification.malign, croppedImage: image, segmentationImage: segmentation.mask)
        
        return result
    }

}

enum CoreEngineErrors: LocalizedError {
    case failureLoadSegmenter
    case segmentationError
    case classificationError
    
    var errorDescription: String? {
        switch self {
        case .failureLoadSegmenter:
            return "Failed to run segmentation model"
        case .segmentationError:
            return "Error in segmentation. No mask segmented"
        case .classificationError:
            return "Error in classification. No classification result"
        }
    }
}


