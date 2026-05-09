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

protocol engine {
    var detector: Detector2? { get }
    var segmenter: ResNetFeatMask8x8Classifier? { get }
    
    func predict(on image: UIImage) -> Research
}

// MARK: CoreEngine class
/// Class for core engine of analysis
class CoreEngine {
    private let detector: Detector2
//    private let segmenter: ResNetFeatMask8x8Classifier
    private let seg: Segmenter
    private let classifier: ResNetFeatMask8x8Classifier?
    
    init() throws {
        self.detector = Detector2()
        self.seg = try Segmenter()
        self.classifier = try ResNetFeatMask8x8Classifier.loadBundled()
    }
    
    func detect(on image: UIImage) async throws -> (cropedImage: UIImage,
                                                    detectedImage: UIImage) {
        let result = try self.detector.detectMole(on: image)
        
        return (result.crop, result.annotaion)
        
    }
    
    // MARK: Segmentation function
    /// Function for segmentation image
    private func segment(image: UIImage) async throws -> (mask: UIImage, maskArray: MLMultiArray, layout: LetterboxLayout) {
        let result = await seg.runSegmentation(on: image)
        
        guard let mask = result.maskResult, let maskArray = result.maskArray, let layout = result.layout else {
            print("no mask")
            throw CoreEngineErrors.segmentationError
        }
        
        return (mask, maskArray, layout)
    }
    
    // MARK: Classification function
    /// Function for classification image. Returns benign and malign probabilities
    private func classify(image: UIImage, binaryMask256: MLMultiArray, deepLabMask: MLMultiArray) throws -> (benign: Double, malign: Double) {
        do {
            let classificationResult = try classifier?.probabilities(
                from: image,
                binaryMask256: binaryMask256,
                deepLabMaskForDump: deepLabMask
            )
            guard let benign = classificationResult?.benign, let malign = classificationResult?.malign else { throw CoreEngineErrors.classificationError }
            return (benign, malign)
        } catch {
            throw CoreEngineErrors.classificationError
        }
        
    }
    
    // MARK: Predict function
    /// Main function for mole analysis. Returns research result
    func predict(on image: UIImage) async throws -> Research {
        let segmentation = try await self.segment(image: image)
        let rawBinary256 = try seg.binaryMask256ForClassifier(fromRawOutput: segmentation.maskArray)
        let binary256 = try seg.etalonAlignedBinaryMask256(fromBinary256: rawBinary256, letterboxLayout: segmentation.layout)
        let classification = try self.classify(image: image, binaryMask256: binary256, deepLabMask: segmentation.maskArray)
        
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


