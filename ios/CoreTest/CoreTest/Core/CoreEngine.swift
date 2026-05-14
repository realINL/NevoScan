//
//  CoreEngine.swift
//  NevoScan
//
//  Created by Илья Лебедев on 14.03.2026.
//

import Foundation
//import YOLO
import UIKit
import CoreML

protocol engine {
//    var detector: Detector2? { get }
    var segmenter: ResNetFeatMask8x8Classifier? { get }
    
    func predict(on image: UIImage) -> Research
}

// MARK: CoreEngine class
/// Class for core engine of analysis
class CoreEngine {
//    private let detector: Detector2
//    private let segmenter: ResNetFeatMask8x8Classifier
    private let seg: SegmenterProtocol
    private let classifier: Classifier?
    
    init() throws {
//        self.detector = Detector2()
//        self.seg = try Segmenter()
        self.seg = try SegmenterImageType()
        self.classifier = try Classifier()
    }
    
//    func detect(on image: UIImage) async throws -> (cropedImage: UIImage,
//                                                    detectedImage: UIImage) {
//        let result = try self.detector.detectMole(on: image)
//        
//        return (result.crop, result.annotaion)
//        
//    }
    
    // MARK: Segmentation function
    /// Function for segmentation image
    private func segment(image: UIImage) async throws -> (mask: UIImage, maskArray: MLMultiArray)  {
        let result = await seg.runSegmentation(on: image)
        
        guard let mask = result.maskResult, let maskArray = result.maskArray else { print("no mask"); throw CoreEngineErrors.segmentationError }
        
        return (mask, maskArray)
    }
    
    // MARK: Classification function
    /// Function for classification image. Returns benign and malign probabilities
//    private func classify(image: UIImage, mask: UIImage) throws -> (benign: Double, malign: Double) {
//        do {
//            let classificationResult = try classifier?.probabilities(from: image, maskImage: mask)
////            let classificationResult = try classifier?.probabilities(from: image, deepLabMask: mask)
//            guard let benign = classificationResult?.benign, let malign = classificationResult?.malign else { throw CoreEngineErrors.classificationError }
//            return (benign, malign)
//        } catch {
//            throw CoreEngineErrors.classificationError
//        }
//        
//    }
//    
//    // MARK: Predict function
//    /// Main function for mole analysis. Returns research result
//    func predict(on image: UIImage) async throws -> Research {
//        let segmentation = try await self.segment(image: image)
//        let classification = try self.classify(image: image, mask: segmentation.mask)
//        
//        let result = Research(benignProbability: classification.benign, malignProbability: classification.malign, croppedImage: image, segmentationImage: segmentation.mask)
//        
//        return result
//    }
    private func classify(image: UIImage, binaryMask256: MLMultiArray, deepLabMask: MLMultiArray) throws -> (benign: Double, malign: Double) {
        do {
            let classificationResult = try classifier?.classify(image: image, segmentationOutput: binaryMask256)
//            (
//                from: image,
//                binaryMask256: binaryMask256,
//                deepLabMaskForDump: deepLabMask
//            )
            guard let benign = classificationResult?.benign, let malign = classificationResult?.malign else { throw CoreEngineErrors.classificationError }
            return (benign, malign)
        } catch {
            throw CoreEngineErrors.classificationError
        }
        
    }
    
    // MARK: Predict function
    /// Main function for mole analysis. Returns research result
    func predict(on image: UIImage) async throws -> Research {
        #if DEBUG
        PipelineDebugRecorder.reset()
        #endif
        let segmentation = try await self.segment(image: image)
        let binary256 = try seg.binaryMask256ForClassifier(fromRawOutput: segmentation.maskArray)
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

//class Detector2 {
//    var model: YOLO
//    
//    init() {
//        self.model = YOLO("best", task: .detect)
//    }
//    
//    func detectMole(on image: UIImage) throws -> (crop: UIImage, annotaion: UIImage) {
//        let result = model(image)
//        guard !result.boxes.isEmpty else { throw DetectorErrors.notFound}
//        
//        guard let croppedImage = cropImage(image: image, result: result) else {
//            throw DetectorErrors.croppingError
//        }
//        
//        guard let annotatedImage = drawBox(image: image, result: result) else {
//            throw DetectorErrors.drawingError
//        }
//        
//        return(croppedImage, annotatedImage)
//        
//    }
//    
//    // MARK: Cropping image to detected box
//    private func cropImage(image: UIImage, result: YOLOResult) -> UIImage? {
//        let cgImage = image.cgImage
//        let rect = result.boxes.first!.xywh
//        
//        if let croppedImage = cgImage?.cropping(to: rect) {
//            return UIImage(cgImage: croppedImage)
//        } else {
//            return nil
//        }
//    }
//    
//    // MARK: Drawing box
//    /// Drawing box of detected mole
//    private func drawBox(image: UIImage, result: YOLOResult) -> UIImage? {
//        let box = result.boxes.first!
//        guard let ciImage = CIImage(image: image) else { return nil }
//        let context = CIContext(options: nil)
//        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
//            return UIImage()
//        }
//        let width = cgImage.width
//        let height = cgImage.height
//        let imageSize = CGSize(width: width, height: height)
//        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
//        guard let drawContext = UIGraphicsGetCurrentContext() else {
//            UIGraphicsEndImageContext()
//            return UIImage()
//        }
//        drawContext.saveGState()
//        drawContext.translateBy(x: 0, y: CGFloat(height))
//        drawContext.scaleBy(x: 1, y: -1)
//        drawContext.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))
//        drawContext.restoreGState()
//        
//        let rect = box.xywh
//        
//        // Затеменеие
//        let fullPath = UIBezierPath(rect: CGRect(origin: .zero, size: image.size))
//        let rectPath = UIBezierPath(rect: rect)
//        
//        fullPath.append(rectPath)
//        fullPath.usesEvenOddFillRule = true
//        
//        drawContext.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
//        fullPath.fill()
//        
//        // Выделение
//        let lineWidth = 10
//        let color = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
//        let path = UIBezierPath(roundedRect: rect, cornerRadius: 15)
//        drawContext.setStrokeColor(color)
//        drawContext.setLineWidth(CGFloat(lineWidth))
//        drawContext.addPath(path.cgPath)
//        drawContext.strokePath()
//        
//        
//        let drawnImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
//        UIGraphicsEndImageContext()
//        return drawnImage
//    }
//    
//    
//}

enum DetectorErrors: LocalizedError {
    case notFound
    case croppingError
    case drawingError
    case segmantationError
    
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Не удалось найти родинку на изображении"
        default:
            return "Ошибка при обработке фото"
        }
    }
}
