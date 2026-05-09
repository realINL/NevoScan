////
////  ResNetFeatMaskClassifier.swift
////  NevoScan
////
////
//
//import CoreImage
//import CoreImage.CIFilterBuiltins
//import CoreML
//import Foundation
//import UIKit
//
//enum ResNetFeatMaskError: LocalizedError {
//    case modelNotFound
//    case couldNotPrepareImage
//    case predictionFailed(Error)
//    case missingOutput(String)
//
//    var errorDescription: String? {
//        switch self {
//        case .modelNotFound:
//            return "Модель классификации не найдена в приложении."
//        case .couldNotPrepareImage:
//            return "Не удалось подготовить изображение для классификации"
//        case .predictionFailed(let e):
//            return e.localizedDescription
//        case .missingOutput(let name):
//            return "Нет выхода модели: \(name)"
//        }
//    }
//}
//
//enum ResNetFeatMaskConfig {
//    static let size = 256
//    static let imageInput = "image"
//    static let maskInput = "mask"
//    static let output = "output"
//    static let malignClassIndex = 1
//}
//
//struct ResNetFeatMaskClassifier {
//    private let model: MLModel
//
//    init(mlModel: MLModel) {
//        self.model = mlModel
//    }
//
//    static func loadBundled() throws -> ResNetFeatMaskClassifier {
//        let names = ["ResNetFeatMask", "ResNet", "Classifier"]
//        for name in names {
//            if let url = Bundle.main.url(forResource: name, withExtension: "mlpackage")
//                ?? Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
//                return ResNetFeatMaskClassifier(mlModel: try MLModel(contentsOf: url))
//            }
//        }
//        throw ResNetFeatMaskError.modelNotFound
//    }
//
//    /// Возвращает обе вероятности из `softmax`: benign (0) и malign (1).
//    func probabilities(from image: UIImage, mask256: MLMultiArray) throws -> (benign: Double, malign: Double) {
//        guard let resized = image.normalizedUp().resized256(),
//              let pixelBuffer = resized.toPixelBuffer256() else {
//            throw ResNetFeatMaskError.couldNotPrepareImage
//        }
//
//        let provider = try MLDictionaryFeatureProvider(dictionary: [
//            ResNetFeatMaskConfig.imageInput: MLFeatureValue(pixelBuffer: pixelBuffer),
//            ResNetFeatMaskConfig.maskInput: MLFeatureValue(multiArray: mask256),
//        ])
//
//        let out: MLFeatureProvider
//        do {
//            out = try model.prediction(from: provider)
//        } catch {
//            throw ResNetFeatMaskError.predictionFailed(error)
//        }
//
//        guard let logits = out.featureValue(for: ResNetFeatMaskConfig.output)?.multiArrayValue else {
//            throw ResNetFeatMaskError.missingOutput(ResNetFeatMaskConfig.output)
//        }
//        return softmaxProbabilities(logits: logits)
//    }
//}
//
//// MARK: - Helpers
//
//private func softmaxProbabilities(logits: MLMultiArray) -> (benign: Double, malign: Double) {
//    let shape = logits.shape.map { $0.intValue }
//    let count = shape.reduce(1, *)
//    guard count >= 2 else { return (0, 0) }
//
//    let v0: Double
//    let v1: Double
//    if shape.count == 2 {
//        v0 = Double(truncating: logits[[0, 0] as [NSNumber]])
//        v1 = Double(truncating: logits[[0, 1] as [NSNumber]])
//    } else {
//        v0 = Double(truncating: logits[[0] as [NSNumber]])
//        v1 = Double(truncating: logits[[1] as [NSNumber]])
//    }
//    let m = max(v0, v1)
//    let e0 = exp(v0 - m)
//    let e1 = exp(v1 - m)
//    let sum = e0 + e1
//    return (e0 / sum, e1 / sum)
//}
//
//


//
//  ResNetFeatMaskClassifier.swift
//  NevoScan
//
//

import CoreImage
import CoreImage.CIFilterBuiltins
import CoreML
import Foundation
import UIKit

enum ResNetFeatMaskError: LocalizedError {
    case modelNotFound
    case couldNotPrepareImage
    case predictionFailed(Error)
    case missingOutput(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Модель классификации не найдена в приложении."
        case .couldNotPrepareImage:
            return "Не удалось подготовить изображение для классификации"
        case .predictionFailed(let e):
            return e.localizedDescription
        case .missingOutput(let name):
            return "Нет выхода модели: \(name)"
        }
    }
}

enum ResNetFeatMaskConfig {
    static let size = 256
    static let imageInput = "image"
    static let maskInput = "mask"
    static let output = "output"
    static let malignClassIndex = 1
    static let malignThreshold = 0.3
    static let benignLabel = "Доброкачественное"
    static let malignLabel = "Злокачественное"
}

struct ResNetFeatMaskPrediction {
    let result: String
    let probabilityMalign: Double
    let probabilityBenign: Double
}

struct ResNetFeatMaskClassifier {
    private let model: MLModel

    init(mlModel: MLModel) {
        self.model = mlModel
    }

    static func loadBundled() throws -> ResNetFeatMaskClassifier {
        let names = ["ResNetFeatMask", "ResNet", "Classifier"]
        for name in names {
            if let url = Bundle.main.url(forResource: name, withExtension: "mlpackage")
                ?? Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
                return ResNetFeatMaskClassifier(mlModel: try MLModel(contentsOf: url))
            }
        }
        throw ResNetFeatMaskError.modelNotFound
    }

    /// Возвращает обе вероятности из `softmax`: benign (0) и malign (1).
    func probabilities(from image: UIImage, mask256: MLMultiArray) throws -> (benign: Double, malign: Double) {
        guard let prepared = image.preparedForResNetClassification(),
              let resized = prepared.resized256(),
              let pixelBuffer = resized.toPixelBuffer256() else {
            throw ResNetFeatMaskError.couldNotPrepareImage
        }

        let provider = try MLDictionaryFeatureProvider(dictionary: [
            ResNetFeatMaskConfig.imageInput: MLFeatureValue(pixelBuffer: pixelBuffer),
            ResNetFeatMaskConfig.maskInput: MLFeatureValue(multiArray: mask256),
        ])

        let out: MLFeatureProvider
        do {
            out = try model.prediction(from: provider)
        } catch {
            throw ResNetFeatMaskError.predictionFailed(error)
        }

        guard let logits = out.featureValue(for: ResNetFeatMaskConfig.output)?.multiArrayValue else {
            throw ResNetFeatMaskError.missingOutput(ResNetFeatMaskConfig.output)
        }
        return softmaxProbabilities(logits: logits)
    }

    func predict(from image: UIImage, mask256: MLMultiArray) throws -> ResNetFeatMaskPrediction {
        let probs = try probabilities(from: image, mask256: mask256)
        let isMalign = probs.malign >= ResNetFeatMaskConfig.malignThreshold
        let label = isMalign ? ResNetFeatMaskConfig.malignLabel : ResNetFeatMaskConfig.benignLabel
        return ResNetFeatMaskPrediction(
            result: label,
            probabilityMalign: probs.malign,
            probabilityBenign: probs.benign
        )
    }
}

// MARK: - Helpers

private func softmaxProbabilities(logits: MLMultiArray) -> (benign: Double, malign: Double) {
    let shape = logits.shape.map { $0.intValue }
    let count = shape.reduce(1, *)
    guard count >= 2 else { return (0, 0) }

    let v0: Double
    let v1: Double
    if shape.count == 2 {
        v0 = Double(truncating: logits[[0, 0] as [NSNumber]])
        v1 = Double(truncating: logits[[0, 1] as [NSNumber]])
    } else {
        v0 = Double(truncating: logits[[0] as [NSNumber]])
        v1 = Double(truncating: logits[[1] as [NSNumber]])
    }
    let m = max(v0, v1)
    let e0 = exp(v0 - m)
    let e1 = exp(v1 - m)
    let sum = e0 + e1
    return (e0 / sum, e1 / sum)
}


extension UIImage {
    func preparedForResNetClassification() -> UIImage? {
        let oriented = normalizedUp()
        return oriented.strippingAlphaOnWhite()
    }

    func normalizedUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func resized256() -> UIImage? {
        let target = CGSize(width: ResNetFeatMaskConfig.size, height: ResNetFeatMaskConfig.size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in
            UIGraphicsGetCurrentContext()?.interpolationQuality = .medium
            draw(in: CGRect(origin: .zero, size: target))
        }
    }

    func toPixelBuffer256() -> CVPixelBuffer? {
        guard let cgImage = cgImage else { return nil }
        let w = ResNetFeatMaskConfig.size
        let h = ResNetFeatMaskConfig.size
        var pxbuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            w,
            h,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pxbuffer
        )
        guard status == kCVReturnSuccess, let buffer = pxbuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: baseAddress,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        ) else { return nil }

        ctx.interpolationQuality = .high
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
        return buffer
    }

    private func strippingAlphaOnWhite() -> UIImage? {
        guard let cg = cgImage else { return nil }
        if !cg.hasAlphaChannel {
            return self
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

extension CGImage {
    var hasAlphaChannel: Bool {
        switch alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        default:
            return true
        }
    }

    func rgbToBgr(data: inout [UInt8]) {
        for i in stride(from: 0, to: data.count, by: 3) {
            (data[i], data[i + 2]) = (data[i + 2], data[i])
        }
    }
}

