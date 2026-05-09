//
//  ResNetFeatMask8x8Classifier.swift
//  NevoScan
//
//  Created by Илья Лебедев on 11.04.2026.
//

import CoreGraphics
import CoreML
import Foundation
import UIKit

enum ResNetFeatMask8x8Error: LocalizedError {
    case modelNotFound
    case couldNotPrepareImage
    case predictionFailed(Error)
    case missingOutput(String)
    case unexpectedMaskShape([NSNumber])

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
        case .unexpectedMaskShape(let s):
            return "Неожиданная форма маски сегментатора: \(s.map { $0.intValue })"
        }
    }
}

enum ResNetFeatMask8x8Config {

    static let size = 256
    static let maskSmallSide = 8
    static let maskChannels = 2048
    static let imageInput = "image"
    static let maskInput = "mask"
    static let outputNameCandidates = ["var_806", "output", "activation_out", "var_1"]

    static let malignClassIndex = 1
    static let malignThreshold = 0.3
    static let benignLabel = "Доброкачественное"
    static let malignLabel = "Злокачественное"

    static let maskThreshold: Float = 0.5
    
    static let meanRGB: [Float] = [0.485, 0.456, 0.406]
    static let stdRGB: [Float] = [0.229, 0.224, 0.225]
}

struct ResNetFeatMask8x8Prediction {
    let result: String
    let probabilityMalign: Double
    let probabilityBenign: Double
}

struct ResNetFeatMask8x8Classifier {
    private let model: MLModel

    init(mlModel: MLModel) {
        self.model = mlModel
    }

    
    static func loadBundled() throws -> ResNetFeatMask8x8Classifier {
        let names = [
            "classification_model",
            "ResNetFeatMask",
            "ResNet",
            "Classifier",
        ]
        for name in names {
            if let url = Bundle.main.url(forResource: name, withExtension: "mlpackage")
                ?? Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
                return ResNetFeatMask8x8Classifier(mlModel: try MLModel(contentsOf: url))
            }
        }
        throw ResNetFeatMask8x8Error.modelNotFound
    }


    func probabilities(from image: UIImage, deepLabMask: MLMultiArray) throws -> (benign: Double, malign: Double) {
        let binary256 = try binaryMask256FromSegmenterRaw(deepLabMask)
        return try probabilities(from: image, binaryMask256: binary256, deepLabMaskForDump: deepLabMask)
    }

    func probabilities(from image: UIImage, binaryMask256: MLMultiArray, deepLabMaskForDump: MLMultiArray) throws -> (benign: Double, malign: Double) {
        let normalized = try imageNetNormalizedNCHW256(from: image)
        let maskSmall2048 = try classifierMaskTensor2048x8(fromBinaryMask256: binaryMask256)
        let provider = try MLDictionaryFeatureProvider(dictionary: [
            ResNetFeatMask8x8Config.imageInput: MLFeatureValue(multiArray: normalized),
            ResNetFeatMask8x8Config.maskInput: MLFeatureValue(multiArray: maskSmall2048),
        ])

        let out: MLFeatureProvider
        do {
            out = try model.prediction(from: provider)
        } catch {
            throw ResNetFeatMask8x8Error.predictionFailed(error)
        }

        guard let logits = try logitsArray(from: out) else {
            throw ResNetFeatMask8x8Error.missingOutput("logits")
        }
        let probs = softmaxProbabilities(logits: logits)
        dumpPipelineIfNeeded(
            imageTensor: normalized,
            deepLabMask: deepLabMaskForDump,
            maskTensor2048: maskSmall2048,
            logits: logits,
            probs: probs
        )
        return probs
    }

    func predict(from image: UIImage, deepLabMask: MLMultiArray) throws -> ResNetFeatMask8x8Prediction {
        let probs = try probabilities(from: image, deepLabMask: deepLabMask)
        let isMalign = probs.malign >= ResNetFeatMask8x8Config.malignThreshold
        let label = isMalign ? ResNetFeatMask8x8Config.malignLabel : ResNetFeatMask8x8Config.benignLabel
        return ResNetFeatMask8x8Prediction(
            result: label,
            probabilityMalign: probs.malign,
            probabilityBenign: probs.benign
        )
    }
}

// MARK: - Debug dump for 1:1 Python comparison

private struct PipelineDump: Codable {
    let timestamp: String
    let imageShape: [Int]
    let deepLabMaskShape: [Int]
    let maskTensorShape: [Int]
    let logitsShape: [Int]
    let imageSampleCHW_3x4x4: [[[Float]]]
    let deepLabMaskSample8x8: [[Float]]
    let mask8x8Channel0: [[Float]]
    let logits: [Float]
    let probabilityBenign: Double
    let probabilityMalign: Double
}

private func dumpPipelineIfNeeded(
    imageTensor: MLMultiArray,
    deepLabMask: MLMultiArray,
    maskTensor2048: MLMultiArray,
    logits: MLMultiArray,
    probs: (benign: Double, malign: Double)
) {
#if DEBUG
    let enabled = UserDefaults.standard.bool(forKey: "nv_debug_pipeline_dump")
    guard enabled else { return }
    guard
        let imageSample = sampleImage3x4x4(imageTensor),
        let deepLabSample = sampleMask8x8From256(deepLabMask),
        let maskSmall = sampleMask8x8Channel0(maskTensor2048),
        let logitsVals = readLogits(logits)
    else { return }

    let payload = PipelineDump(
        timestamp: ISO8601DateFormatter().string(from: Date()),
        imageShape: imageTensor.shape.map { $0.intValue },
        deepLabMaskShape: deepLabMask.shape.map { $0.intValue },
        maskTensorShape: maskTensor2048.shape.map { $0.intValue },
        logitsShape: logits.shape.map { $0.intValue },
        imageSampleCHW_3x4x4: imageSample,
        deepLabMaskSample8x8: deepLabSample,
        mask8x8Channel0: maskSmall,
        logits: logitsVals,
        probabilityBenign: probs.benign,
        probabilityMalign: probs.malign
    )
    writePipelineDump(payload)
#endif
}

private func writePipelineDump(_ payload: PipelineDump) {
    do {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let file = docs.appendingPathComponent("pipeline_dump_\(Int(Date().timeIntervalSince1970)).json")
        try data.write(to: file, options: .atomic)
        print("Pipeline dump saved: \(file.path)")
    } catch {
        print("Pipeline dump write error: \(error)")
    }
}

private func sampleImage3x4x4(_ image: MLMultiArray) -> [[[Float]]]? {
    let s = image.shape.map { $0.intValue }
    guard s.count == 4, s[0] == 1, s[1] >= 3, s[2] >= 4, s[3] >= 4 else { return nil }
    var out = Array(repeating: Array(repeating: Array(repeating: Float(0), count: 4), count: 4), count: 3)
    for c in 0..<3 {
        for y in 0..<4 {
            for x in 0..<4 {
                out[c][y][x] = Float(truncating: image[[0, c, y, x] as [NSNumber]])
            }
        }
    }
    return out
}

private func sampleMask8x8From256(_ mask: MLMultiArray) -> [[Float]]? {
    let shape = mask.shape.map { $0.intValue }
    guard shape.count >= 2 else { return nil }
    let h = shape[shape.count - 2]
    let w = shape[shape.count - 1]
    guard h == 256, w == 256 else { return nil }
    var out = Array(repeating: Array(repeating: Float(0), count: 8), count: 8)
    for oy in 0..<8 {
        for ox in 0..<8 {
            let sy = oy * 32
            let sx = ox * 32
            out[oy][ox] = (try? deepLabMaskValueChannel0(mask: mask, y: sy, x: sx)) ?? 0
        }
    }
    return out
}

/// Как `seg_mask[0, 0, y, x]` в `debug_compare_pipeline.sample_deeplab_8x8` (всегда нулевой канал сегментации).
private func deepLabMaskValueChannel0(mask: MLMultiArray, y: Int, x: Int) throws -> Float {
    let shape = mask.shape.map { $0.intValue }
    let strides = mask.strides.map { $0.intValue }
    guard shape.count >= 2, shape.count == strides.count else {
        throw ResNetFeatMask8x8Error.unexpectedMaskShape(mask.shape)
    }
    let h = shape[shape.count - 2]
    let w = shape[shape.count - 1]
    guard h == ResNetFeatMask8x8Config.size, w == ResNetFeatMask8x8Config.size else {
        throw ResNetFeatMask8x8Error.unexpectedMaskShape(mask.shape)
    }
    guard y >= 0, y < h, x >= 0, x < w else {
        throw ResNetFeatMask8x8Error.unexpectedMaskShape(mask.shape)
    }

    let raw: Float
    if shape.count == 4, shape[0] == 1 {
        let o = mlaLinearOffset(strides: strides, indices: [0, 0, y, x])
        raw = mlaReadFloat(mask, linear: o)
    } else if shape.count == 3 {
        let o = mlaLinearOffset(strides: strides, indices: [0, y, x])
        raw = mlaReadFloat(mask, linear: o)
    } else if shape.count == 2 {
        let o = mlaLinearOffset(strides: strides, indices: [y, x])
        raw = mlaReadFloat(mask, linear: o)
    } else {
        var idx = Array(repeating: 0, count: shape.count)
        idx[shape.count - 2] = y
        idx[shape.count - 1] = x
        let o = mlaLinearOffset(strides: strides, indices: idx)
        raw = mlaReadFloat(mask, linear: o)
    }
    if raw < 0 || raw > 1 {
        return maskSigmoid(raw)
    }
    return min(max(raw, 0), 1)
}

private func sampleMask8x8Channel0(_ maskSmall: MLMultiArray) -> [[Float]]? {
    let s = maskSmall.shape.map { $0.intValue }
    guard s.count == 4, s[0] == 1, s[1] >= 1, s[2] == 8, s[3] == 8 else { return nil }
    var out = Array(repeating: Array(repeating: Float(0), count: 8), count: 8)
    for y in 0..<8 {
        for x in 0..<8 {
            out[y][x] = Float(truncating: maskSmall[[0, 0, y, x] as [NSNumber]])
        }
    }
    return out
}

private func readLogits(_ logits: MLMultiArray) -> [Float]? {
    let shape = logits.shape.map { $0.intValue }
    if shape.count == 2, shape[0] == 1, shape[1] >= 2 {
        return [
            Float(truncating: logits[[0, 0] as [NSNumber]]),
            Float(truncating: logits[[0, 1] as [NSNumber]]),
        ]
    }
    if shape.count == 1, shape[0] >= 2 {
        return [
            Float(truncating: logits[[0] as [NSNumber]]),
            Float(truncating: logits[[1] as [NSNumber]]),
        ]
    }
    return nil
}

// MARK: - Model IO

private func logitsArray(from out: MLFeatureProvider) throws -> MLMultiArray? {
    for name in ResNetFeatMask8x8Config.outputNameCandidates {
        if let arr = out.featureValue(for: name)?.multiArrayValue {
            return arr
        }
    }
    let desc = out.featureNames.compactMap { name -> MLMultiArray? in
        out.featureValue(for: name)?.multiArrayValue
    }
    return desc.first
}

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

private func imageNetNormalizedNCHW256(from image: UIImage) throws -> MLMultiArray {
    guard let prepared = image.preparedForClassifierInference(),
          let resized = prepared.resizedClassifier256(),
          let cg = resized.cgImage else {
        throw ResNetFeatMask8x8Error.couldNotPrepareImage
    }
    let w = cg.width
    let h = cg.height
    guard w == ResNetFeatMask8x8Config.size, h == ResNetFeatMask8x8Config.size else {
        throw ResNetFeatMask8x8Error.couldNotPrepareImage
    }

    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * w
    var raw = [UInt8](repeating: 0, count: h * bytesPerRow)
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        throw ResNetFeatMask8x8Error.couldNotPrepareImage
    }
    guard let ctx = CGContext(
        data: &raw,
        width: w,
        height: h,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw ResNetFeatMask8x8Error.couldNotPrepareImage
    }
    ctx.interpolationQuality = .none
    ctx.translateBy(x: 0, y: CGFloat(h))
    ctx.scaleBy(x: 1, y: -1)
    ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

    let out = try MLMultiArray(shape: [1, 3, NSNumber(value: h), NSNumber(value: w)], dataType: .float32)
    let mean = ResNetFeatMask8x8Config.meanRGB
    let std = ResNetFeatMask8x8Config.stdRGB
    for y in 0..<h {
        for x in 0..<w {
            let o = y * bytesPerRow + x * bytesPerPixel
            let rf = Float(raw[o]) / 255
            let gf = Float(raw[o + 1]) / 255
            let bf = Float(raw[o + 2]) / 255
            out[[0, 0, y, x] as [NSNumber]] = NSNumber(value: (rf - mean[0]) / std[0])
            out[[0, 1, y, x] as [NSNumber]] = NSNumber(value: (gf - mean[1]) / std[1])
            out[[0, 2, y, x] as [NSNumber]] = NSNumber(value: (bf - mean[2]) / std[2])
        }
    }
    return out
}

private func classifierMaskTensor2048x8(fromBinaryMask256 mask: MLMultiArray) throws -> MLMultiArray {
    let mh = ResNetFeatMask8x8Config.maskSmallSide
    let mw = ResNetFeatMask8x8Config.maskSmallSide
    let c = ResNetFeatMask8x8Config.maskChannels
    let h256 = ResNetFeatMask8x8Config.size
    let scale = h256 / mh

    let shape = mask.shape.map { $0.intValue }
    guard shape.count == 4, shape[0] == 1, shape[1] == 1, shape[2] == h256, shape[3] == h256 else {
        throw ResNetFeatMask8x8Error.unexpectedMaskShape(mask.shape)
    }

    let out = try MLMultiArray(shape: [1, NSNumber(value: c), NSNumber(value: mh), NSNumber(value: mw)], dataType: .float32)

    for oy in 0..<mh {
        for ox in 0..<mw {
            let sy = oy * scale
            let sx = ox * scale
            let v = Float(truncating: mask[[0, 0, sy, sx] as [NSNumber]])
            let bin: Float = v > ResNetFeatMask8x8Config.maskThreshold ? 1 : 0
            for ch in 0..<c {
                out[[0, ch, oy, ox] as [NSNumber]] = NSNumber(value: bin)
            }
        }
    }
    return out
}

private func binaryMask256FromSegmenterRaw(_ mask: MLMultiArray) throws -> MLMultiArray {
    let h = ResNetFeatMask8x8Config.size
    let w = ResNetFeatMask8x8Config.size
    let shape = mask.shape.map { $0.intValue }
    guard shape.count >= 2 else {
        throw ResNetFeatMask8x8Error.unexpectedMaskShape(mask.shape)
    }
    let mh = shape[shape.count - 2]
    let mw = shape[shape.count - 1]
    guard mh == h, mw == w else {
        throw ResNetFeatMask8x8Error.unexpectedMaskShape(mask.shape)
    }

    let out = try MLMultiArray(shape: [1, 1, NSNumber(value: h), NSNumber(value: w)], dataType: .float32)
    let strides = mask.strides.map { $0.intValue }
    guard strides.count == shape.count else {
        throw ResNetFeatMask8x8Error.unexpectedMaskShape(mask.shape)
    }

    let t = ResNetFeatMask8x8Config.maskThreshold
    for y in 0..<h {
        for x in 0..<w {
            var idx = Array(repeating: 0, count: shape.count)
            idx[shape.count - 2] = y
            idx[shape.count - 1] = x
            let o = mlaLinearOffset(strides: strides, indices: idx)
            let raw = mlaReadFloat(mask, linear: o)
            let prob = min(max(raw, 0), 1)
            out[[0, 0, y, x] as [NSNumber]] = NSNumber(value: prob > t ? Float(1) : Float(0))
        }
    }
    return out
}

private func maskSigmoid(_ v: Float) -> Float {
    let z = max(-40, min(40, v))
    return 1 / (1 + exp(-z))
}

private func mlaLinearOffset(strides: [Int], indices: [Int]) -> Int {
    var o = 0
    for i in indices.indices {
        o += indices[i] * strides[i]
    }
    return o
}

private func mlaReadFloat(_ array: MLMultiArray, linear: Int) -> Float {
    let raw = UnsafeMutableRawPointer(array.dataPointer)
    switch array.dataType {
    case .float32:
        return raw.bindMemory(to: Float.self, capacity: array.count)[linear]
    case .double:
        return Float(raw.bindMemory(to: Double.self, capacity: array.count)[linear])
    default:
        return 0
    }
}

// MARK: - UIImage

private extension UIImage {
    func preparedForClassifierInference() -> UIImage? {
        let oriented = normalizedClassifierUp()
        return oriented.strippingAlphaClassifierOnWhite()
    }

    func normalizedClassifierUp() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func resizedClassifier256() -> UIImage? {
        let target = CGSize(width: ResNetFeatMask8x8Config.size, height: ResNetFeatMask8x8Config.size)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        return renderer.image { _ in
            UIGraphicsGetCurrentContext()?.interpolationQuality = .medium
            draw(in: CGRect(origin: .zero, size: target))
        }
    }

    func strippingAlphaClassifierOnWhite() -> UIImage? {
        guard let cg = cgImage else { return nil }
        if cgClassifierHasAlpha(cg) == false {
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

private func cgClassifierHasAlpha(_ cg: CGImage) -> Bool {
    switch cg.alphaInfo {
    case .none, .noneSkipFirst, .noneSkipLast:
        return false
    default:
        return true
    }
}

