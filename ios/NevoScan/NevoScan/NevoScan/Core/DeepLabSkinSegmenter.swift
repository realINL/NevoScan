////
////  DeepLabSkinSegmenter.swift
////  NevoScan
////
////
//
//import CoreGraphics
//import CoreML
//import Foundation
//import UIKit


// MARK: Deprecated

//
//enum DeepLabSegmentationError: LocalizedError {
//    case modelNotFound
//    case predictionFailed(Error)
//    case couldNotPrepareImage
//    case missingOutput(String)
//    case unexpectedMaskShape([NSNumber])
//    
//    var errorDescription: String? {
//        switch self {
//        case .modelNotFound:
//            return "Модель сегментации не найдена в приложении."
//        case .predictionFailed(let e):
//            return e.localizedDescription
//        case .couldNotPrepareImage:
//            return "Не удалось подготовить изображение для сегментации"
//        case .missingOutput(let name):
//            return "Нет выхода модели: \(name)"
//        case .unexpectedMaskShape(let s):
//            return "Неожиданная форма маски: \(s.map { $0.intValue })"
//        }
//    }
//}
//
//private enum DeepLabConfig {
//    static let size = 256
//    static let inputName = "image"
//    static let outputName = "mask"
//    static let maskThreshold: Float = 0.5
//    static let letterboxGray: CGFloat = 114 / 255
//}
//
////struct DeepLabSkinSegmenter {
////    private let model: MLModel
////    
////    init(mlModel: MLModel) {
////        self.model = mlModel
////    }
////    
////    static func loadBundled() throws -> DeepLabSkinSegmenter {
////        
////        let names = ["DeepLabV3Seg", "DeepLabV3", "DeepLab"]
////        for name in names {
////            if let url = Bundle.main.url(forResource: name, withExtension: "mlmodel")
////                ?? Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
////                let ml = try MLModel(contentsOf: url)
////                return DeepLabSkinSegmenter(mlModel: ml)
////            }
////        }
////        throw DeepLabSegmentationError.modelNotFound
////    }
////
////    func predictBinaryMask256(from image: UIImage) throws -> MLMultiArray {
////        try predictBinaryMask256WithLetterboxLayout(from: image).mask256
////    }
////
////    func predictBinaryMask256WithLetterboxLayout(from image: UIImage) throws -> (mask256: MLMultiArray, letterboxLayout: LetterboxLayout) {
////        let prepared = uiImagePreparedForDeepLabInference(image)
////        guard let cgImage = prepared.cgImage else {
////            throw DeepLabSegmentationError.couldNotPrepareImage
////        }
////        
////        let letter = try letterbox256(prepared: prepared, cgImage: cgImage)
////        guard let letterCg = letter.image.cgImage else {
////            throw DeepLabSegmentationError.couldNotPrepareImage
////        }
////        
////        let inputTensor = try rgbNCHWFloatTensor(from256: letterCg)
////        let provider = try MLDictionaryFeatureProvider(dictionary: [
////            DeepLabConfig.inputName: MLFeatureValue(multiArray: inputTensor)
////        ])
////        let out: MLFeatureProvider
////        do {
////            out = try model.prediction(from: provider)
////        } catch {
////            throw DeepLabSegmentationError.predictionFailed(error)
////        }
////        guard let mask = out.featureValue(for: DeepLabConfig.outputName)?.multiArrayValue else {
////            throw DeepLabSegmentationError.missingOutput(DeepLabConfig.outputName)
////        }
////        
////        let mask256 = try toBinaryMask256(mask)
////        return (mask256, letter.layout)
////    }
////
////    func segmentationPreview(from image: UIImage) throws -> UIImage {
////        let (mask256, layout) = try predictBinaryMask256WithLetterboxLayout(from: image)
////        return try binaryMaskUIImage(fromBinaryMask256: mask256, letterboxLayout: layout)
////    }
////    
////    /// Предпросмотр 256×256 без обратного масштабирования.
////    func maskPreviewImage(fromBinaryMask256 mask: MLMultiArray) throws -> UIImage {
////        try binaryMaskUIImage(fromBinaryMask256: mask)
////    }
////    
////    /// Маска 256×256, приведённая к размеру кропа по  геометрии letterbox.
////    func maskPreviewImage(fromBinaryMask256 mask: MLMultiArray, letterboxLayout: LetterboxLayout) throws -> UIImage {
////        try binaryMaskUIImage(fromBinaryMask256: mask, letterboxLayout: letterboxLayout)
////    }
////}
//
//// MARK: - RGB без альфы (аналог Python: if image.shape[2] == 4: image = image[:, :, :3])
//
//
//
//// MARK: - Letterbox 256
//
///// Геометрия letterbox: обратное отображение маски 256×256 .
//struct LetterboxLayout: Sendable {
//    let originalWidth: Int
//    let originalHeight: Int
//    /// Область содержимого кропа в координатах 256×256
//    let contentRect256: CGRect
//    /// Размер и масштаб того же `UIImage`, что ушёл в letterbox (для маски в пунктах, как у кропа).
//    let displayPointSize: CGSize
//    let displayScale: CGFloat
//}
//
//private struct Letterbox256 {
//    let image: UIImage
//    let layout: LetterboxLayout
//}
//
//
//
//private extension UIImage {
//    func normalizedDeepLabOrientation() -> UIImage {
//        guard imageOrientation != .up else { return self }
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = scale
//        let renderer = UIGraphicsImageRenderer(size: size, format: format)
//        return renderer.image { _ in
//            draw(in: CGRect(origin: .zero, size: size))
//        }
//    }
//}
//
//class Segmenter {
//    
//    let config: MLModelConfiguration
//    let model: deeplab
//    
//    init() throws {
//        do {
//            self.config = MLModelConfiguration()
//            self.model = try deeplab(configuration: config)
//        } catch {
//            throw CoreEngineErrors.failureLoadSegmenter
//        }
//    }
//    
//    func runSegmentation(on image: UIImage) async -> (maskResult: UIImage?, maskArray: MLMultiArray?) {
//        weak var model = self.model
//        var maskResult: UIImage?
//        var maskArray: MLMultiArray?
//            do {
//                let prepared = uiImagePreparedForDeepLabInference(image)
//                guard let cgImage = prepared.cgImage else { return (nil, nil) }
//                let letter = try letterbox256(prepared: prepared, cgImage: cgImage)
//                guard let letterCg = letter.image.cgImage else {return (nil, nil) }
//                let inputTensor = try rgbNCHWFloatTensor(from256: letterCg)
//                guard let buffer = letter.image.pixelBuffer(width: 256, height: 256) else { return (nil, nil) }
//                let output = try await model?.prediction(input: deeplabInput(image: inputTensor))
//                guard let mask = output?.mask else { return (nil, nil) }
//                maskArray = mask
//                let binary = try toBinaryMask256(mask)
//                maskResult = try binaryMaskUIImage(fromBinaryMask256: binary, letterboxLayout: letter.layout)
//            } catch {
//                print("Segmentation error: \(error.localizedDescription)")
//                maskResult = nil
//                maskArray = nil
//        }
//        return (maskResult, maskArray)
//    }
//    func binaryMask(from multiArray: MLMultiArray, threshold: Float = 0.5) -> UIImage {
//
//        let ptr = UnsafeMutablePointer<Float32>(
//            OpaquePointer(multiArray.dataPointer)
//        )
//
//        let height = 256
//        let width = 256
//
//        var pixels = [UInt8](repeating: 0, count: width * height)
//
//        for i in 0..<width * height {
//            pixels[i] = ptr[i] > threshold ? 255 : 0
//        }
//
//        let cfData = CFDataCreate(nil, pixels, pixels.count)!
//        let provider = CGDataProvider(data: cfData)!
//
//        let cgImage = CGImage(
//            width: width,
//            height: height,
//            bitsPerComponent: 8,
//            bitsPerPixel: 8,
//            bytesPerRow: width,
//            space: CGColorSpaceCreateDeviceGray(),
//            bitmapInfo: CGBitmapInfo(rawValue: 0),
//            provider: provider,
//            decode: nil,
//            shouldInterpolate: false,
//            intent: .defaultIntent
//        )!
//
//        return UIImage(cgImage: cgImage)
//    }
//    
//    private func convertMultiArrayToMask(_ array: MLMultiArray) -> UIImage {
//        guard array.dataType == .float32 || array.dataType == .double else {
//            return UIImage()
//        }
//        let shape = array.shape.map { $0.intValue }
//        let strides = array.strides.map { $0.intValue }
//        guard shape.count >= 2, shape.count == strides.count else {
//            return UIImage()
//        }
//        let h = shape[shape.count - 2]
//        let w = shape[shape.count - 1]
//        guard h > 0, w > 0 else {
//            return UIImage()
//        }
//        let spatial = h * w
//        let total = array.count
//        guard total % spatial == 0 else {
//            return UIImage()
//        }
//        let groups = total / spatial
//
//        func indicesYX(_ y: Int, _ x: Int) -> [Int] {
//            var idx = Array(repeating: 0, count: shape.count)
//            idx[shape.count - 2] = y
//            idx[shape.count - 1] = x
//            return idx
//        }
//
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bytesPerPixel = 4
//        let bytesPerRow = bytesPerPixel * w
//        var raw = [UInt8](repeating: 0, count: h * bytesPerRow)
//
//        func writePixel(_ y: Int, _ x: Int, white: Bool) {
//            let c: UInt8 = white ? 255 : 0
//            let row = h - 1 - y
//            let o = row * bytesPerRow + x * bytesPerPixel
//            raw[o] = c
//            raw[o + 1] = c
//            raw[o + 2] = c
//            raw[o + 3] = 255
//        }
//
//        if groups == 1 {
//            for y in 0..<h {
//                for x in 0..<w {
//                    let v = mlaReadFloat(array, linear: mlaLinearOffset(strides: strides, indices: indicesYX(y, x)))
//                    let p = maskSigmoid(v)
//                    writePixel(y, x, white: p > 0.5)
//                }
//            }
//        } else if shape.count == 4, shape[0] == 1, shape[1] == groups {
//            let cCount = shape[1]
//            for y in 0..<h {
//                for x in 0..<w {
//                    var bestIdx = 0
//                    var bestVal = -Float.infinity
//                    for c in 0..<cCount {
//                        let lin = mlaLinearOffset(strides: strides, indices: [0, c, y, x])
//                        let v = mlaReadFloat(array, linear: lin)
//                        let s = maskSigmoid(v)
//                        if s > bestVal {
//                            bestVal = s
//                            bestIdx = c
//                        }
//                    }
//                    writePixel(y, x, white: bestIdx != 0)
//                }
//            }
//        } else if shape.count == 3, shape[0] == groups {
//            let cCount = shape[0]
//            for y in 0..<h {
//                for x in 0..<w {
//                    var bestIdx = 0
//                    var bestVal = -Float.infinity
//                    for c in 0..<cCount {
//                        let lin = mlaLinearOffset(strides: strides, indices: [c, y, x])
//                        let v = mlaReadFloat(array, linear: lin)
//                        let s = maskSigmoid(v)
//                        if s > bestVal {
//                            bestVal = s
//                            bestIdx = c
//                        }
//                    }
//                    writePixel(y, x, white: bestIdx != 0)
//                }
//            }
//        } else {
//            return UIImage()
//        }
//
//        guard let outCtx = CGContext(
//            data: &raw,
//            width: w,
//            height: h,
//            bitsPerComponent: 8,
//            bytesPerRow: bytesPerRow,
//            space: colorSpace,
//            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
//        ),
//              let outCg = outCtx.makeImage() else {
//            return UIImage()
//        }
//        return UIImage(cgImage: outCg, scale: 1, orientation: .up)
//    }
//    
//    private func cgImageUsesAlphaChannel(_ cg: CGImage) -> Bool {
//        switch cg.alphaInfo {
//        case .none, .noneSkipFirst, .noneSkipLast:
//            return false
//        default:
//            return true
//        }
//    }
//

//    private func uiImageStrippingAlphaChannel(_ image: UIImage) -> UIImage {
//        guard let cg = image.cgImage, cgImageUsesAlphaChannel(cg) else {
//            return image
//        }
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = image.scale
//        format.opaque = true
//        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
//        return renderer.image { ctx in
//            UIColor.white.setFill()
//            ctx.fill(CGRect(origin: .zero, size: image.size))
//            image.draw(in: CGRect(origin: .zero, size: image.size))
//        }
//    }
//
//    private func uiImagePreparedForDeepLabInference(_ image: UIImage) -> UIImage {
//        let oriented = image.normalizedDeepLabOrientation()
//        return uiImageStrippingAlphaChannel(oriented)
//    }
//    
//    private func letterbox256(prepared: UIImage, cgImage: CGImage) throws -> Letterbox256 {
//        let w = CGFloat(cgImage.width)
//        let h = CGFloat(cgImage.height)
//        let t = CGFloat(DeepLabConfig.size)
//        let r = min(t / h, t / w)
//        
//        let newW = (w * r).rounded()
//        let newH = (h * r).rounded()
//        let dw = (t - newW) / 2
//        let dh = (t - newH) / 2
//        let left = (dw - 0.1).rounded()
//        let top = (dh - 0.1).rounded()
//        
//        let layout = LetterboxLayout(
//            originalWidth: cgImage.width,
//            originalHeight: cgImage.height,
//            contentRect256: CGRect(x: left, y: top, width: newW, height: newH),
//            displayPointSize: prepared.size,
//            displayScale: prepared.scale
//        )
//        
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = 1
//        format.opaque = true
//        
//        let size = CGSize(width: DeepLabConfig.size, height: DeepLabConfig.size)
//        let renderer = UIGraphicsImageRenderer(size: size, format: format)
//        let gray = DeepLabConfig.letterboxGray
//        let img = renderer.image { ctx in
//            UIColor(red: gray, green: gray, blue: gray, alpha: 1).setFill()
//            ctx.fill(CGRect(origin: .zero, size: size))
//            let drawRect = CGRect(x: left, y: top, width: newW, height: newH)
//            ctx.cgContext.interpolationQuality = .high
//            ctx.cgContext.draw(cgImage, in: drawRect)
//        }
//        return Letterbox256(image: img, layout: layout)
//    }
//
//    // MARK: - NCHW tensor 0…255 float32
//
//    private func rgbNCHWFloatTensor(from256 cgImage: CGImage) throws -> MLMultiArray {
//        let w = cgImage.width
//        let h = cgImage.height
//        guard w == DeepLabConfig.size, h == DeepLabConfig.size else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bytesPerPixel = 4
//        let bytesPerRow = bytesPerPixel * w
//        var raw = [UInt8](repeating: 0, count: h * bytesPerRow)
//        guard let ctx = CGContext(
//            data: &raw,
//            width: w,
//            height: h,
//            bitsPerComponent: 8,
//            bytesPerRow: bytesPerRow,
//            space: colorSpace,
//            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
//        ) else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        ctx.translateBy(x: 0, y: CGFloat(h))
//        ctx.scaleBy(x: 1, y: -1)
//        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
//        
//        let multi = try MLMultiArray(shape: [1, 3, NSNumber(value: h), NSNumber(value: w)], dataType: .float32)
//        for y in 0..<h {
//            for x in 0..<w {
//                let row = h - 1 - y
//                let o = row * bytesPerRow + x * bytesPerPixel
//                let r = Float(raw[o])
//                let g = Float(raw[o + 1])
//                let b = Float(raw[o + 2])
//                multi[[0, 0, y, x] as [NSNumber]] = NSNumber(value: r)
//                multi[[0, 1, y, x] as [NSNumber]] = NSNumber(value: g)
//                multi[[0, 2, y, x] as [NSNumber]] = NSNumber(value: b)
//            }
//        }
//        return multi
//    }
//
//    // MARK: - Mask postprocess
//
//    private func maskSigmoid(_ v: Float) -> Float {
//        let z = max(-40, min(40, v))
//        return 1 / (1 + exp(-z))
//    }
//
//    private func mlaLinearOffset(strides: [Int], indices: [Int]) -> Int {
//        var o = 0
//        for i in indices.indices {
//            o += indices[i] * strides[i]
//        }
//        return o
//    }
//
//    private func mlaReadFloat(_ array: MLMultiArray, linear: Int) -> Float {
//        let raw = UnsafeMutableRawPointer(array.dataPointer)
//        switch array.dataType {
//        case .float32:
//            return raw.bindMemory(to: Float.self, capacity: array.count)[linear]
//        case .double:
//            return Float(raw.bindMemory(to: Double.self, capacity: array.count)[linear])
//        default:
//            return 0
//        }
//    }
//
//    private func toBinaryMask256(_ mask: MLMultiArray) throws -> MLMultiArray {
//        let h = DeepLabConfig.size
//        let w = DeepLabConfig.size
//        let shape = mask.shape.map { $0.intValue }
//        guard shape.count >= 2 else {
//            throw DeepLabSegmentationError.unexpectedMaskShape(mask.shape)
//        }
//        let mh = shape[shape.count - 2]
//        let mw = shape[shape.count - 1]
//        guard mh == h, mw == w else {
//            throw DeepLabSegmentationError.unexpectedMaskShape(mask.shape)
//        }
//        
//        let out = try MLMultiArray(shape: [1, 1, NSNumber(value: h), NSNumber(value: w)], dataType: .float32)
//        
//        let strides = mask.strides.map { $0.intValue }
//        guard strides.count == shape.count else {
//            throw DeepLabSegmentationError.unexpectedMaskShape(mask.shape)
//        }
//        
//        let t = DeepLabConfig.maskThreshold
//        for y in 0..<h {
//            for x in 0..<w {
//                var idx = Array(repeating: 0, count: shape.count)
//                idx[shape.count - 2] = y
//                idx[shape.count - 1] = x
//                let o = mlaLinearOffset(strides: strides, indices: idx)
//                let raw = mlaReadFloat(mask, linear: o)
//                let prob = min(max(raw, 0), 1)
//                out[[0, 0, y, x] as [NSNumber]] = NSNumber(value: prob > t ? Float(1) : Float(0))
//            }
//        }
//        return out
//    }
//
//    func binaryMaskUIImage(fromBinaryMask256 mask: MLMultiArray) throws -> UIImage {
//        let h = DeepLabConfig.size
//        let w = DeepLabConfig.size
//        let shape = mask.shape.map { $0.intValue }
//        guard shape == [1, 1, h, w] else {
//            throw DeepLabSegmentationError.unexpectedMaskShape(mask.shape)
//        }
//        
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bytesPerPixel = 4
//        let bytesPerRow = bytesPerPixel * w
//        var raw = [UInt8](repeating: 0, count: h * bytesPerRow)
//        
//        for y in 0..<h {
//            for x in 0..<w {
//                let v = Float(truncating: mask[[0, 0, y, x] as [NSNumber]])
//                let c: UInt8 = v > 0.5 ? 255 : 0
//                let row = h - 1 - y
//                let o = row * bytesPerRow + x * bytesPerPixel
//                raw[o] = c
//                raw[o + 1] = c
//                raw[o + 2] = c
//                raw[o + 3] = 255
//            }
//        }
//        
//        guard let outCtx = CGContext(
//            data: &raw,
//            width: w,
//            height: h,
//            bitsPerComponent: 8,
//            bytesPerRow: bytesPerRow,
//            space: colorSpace,
//            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
//        ),
//              let outCg = outCtx.makeImage() else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        return UIImage(cgImage: outCg, scale: 1, orientation: .up)
//    }
//
//    func binaryMaskUIImage(fromBinaryMask256 mask: MLMultiArray, letterboxLayout: LetterboxLayout) throws -> UIImage {
//        let mask256 = try binaryMaskUIImage(fromBinaryMask256: mask)
//        guard let cg256 = mask256.cgImage else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        let canvas = CGFloat(DeepLabConfig.size)
//        let bounds = CGRect(x: 0, y: 0, width: canvas, height: canvas)
//        let crop = letterboxLayout.contentRect256.integral.intersection(bounds)
//        guard crop.width >= 1, crop.height >= 1 else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        guard let croppedCg = cg256.cropping(to: crop) else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        let ow = letterboxLayout.originalWidth
//        let oh = letterboxLayout.originalHeight
//        guard ow > 0, oh > 0 else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        let outSize = letterboxLayout.displayPointSize
//        guard outSize.width > 0, outSize.height > 0 else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = letterboxLayout.displayScale
//        format.opaque = true
//        let renderer = UIGraphicsImageRenderer(size: outSize, format: format)
//        return renderer.image { ctx in
//            UIColor.black.setFill()
//            ctx.fill(CGRect(origin: .zero, size: outSize))
//            ctx.cgContext.interpolationQuality = .none
//            let cropped = UIImage(cgImage: croppedCg, scale: 1, orientation: .up)
//            cropped.draw(in: CGRect(origin: .zero, size: outSize))
//        }
//    }
//    
//    
//    
//}





//
//  DeepLabSkinSegmenter.swift
//  NevoScan
//

import CoreGraphics
import CoreML
import Foundation
import UIKit
import CoreImage
import VideoToolbox
enum DeepLabSegmentationError: LocalizedError {
    case modelNotFound
    case predictionFailed(Error)
    case couldNotPrepareImage
    case missingOutput(String)
    case unexpectedMaskShape([NSNumber])
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Модель сегментации не найдена в приложении."
        case .predictionFailed(let e):
            return e.localizedDescription
        case .couldNotPrepareImage:
            return "Не удалось подготовить изображение для сегментации"
        case .missingOutput(let name):
            return "Нет выхода модели: \(name)"
        case .unexpectedMaskShape(let s):
            return "Неожиданная форма маски: \(s.map { $0.intValue })"
        }
    }
}

private enum DeepLabConfig {
    static let size = 256
    static let inputName = "image"
    static let outputName = "mask"
    static let maskThreshold: Float = 0.5
}

private enum DeepLabColorSpace {
    static let sRGBOrFallback: CGColorSpace = {
        if let srgb = CGColorSpace(name: CGColorSpace.sRGB) {
            return srgb
        }
        return CGColorSpaceCreateDeviceRGB()
    }()
}


struct LetterboxLayout: Sendable {
    let originalWidth: Int
    let originalHeight: Int
    let contentRect256: CGRect
   
    let displayPointSize: CGSize
    let displayScale: CGFloat
}

private struct Letterbox256 {
    let image: UIImage
    let layout: LetterboxLayout
}





//class Segmenter {
//    
//    let config: MLModelConfiguration
//    let model: deeplab
//    
//    init() throws {
//        do {
//            self.config = MLModelConfiguration()
//            self.model = try deeplab(configuration: config)
//        } catch {
//            throw CoreEngineErrors.failureLoadSegmenter
//        }
//    }
//    
//    func runSegmentation(on image: UIImage) async -> (maskResult: UIImage?, maskArray: MLMultiArray?, layout: LetterboxLayout?) {
//        var maskResult: UIImage?
//        var maskArray: MLMultiArray?
//        var layoutOut: LetterboxLayout?
//        do {
//            let prepared = uiImagePreparedForDeepLabInference(image)
//            guard let cgImage = prepared.cgImage else {
//                print("Segmenter: после подготовки cgImage == nil")
//                return (nil, nil, nil)
//            }
//            let letter = try resizeStretch256(prepared: prepared, cgImage: cgImage)
//            layoutOut = letter.layout
//            guard let letterCg = letter.image.cgImage else {
//                print("Segmenter: resize 256 cgImage == nil")
//                return (nil, nil, nil)
//            }
//            let inputTensor = try rgbNCHWFloatTensor(from256: letterCg)
//            let output = try await model.prediction(input: deeplabInput(image: inputTensor))
//            let mask = output.mask
//            maskArray = mask
//            let binary = try toBinaryMask256(mask)
//            maskResult = try binaryMaskUIImage(fromBinaryMask256: binary, letterboxLayout: letter.layout)
//        } catch {
//            print("Segmentation error: \(error)")
//            maskResult = nil
//            maskArray = nil
//            layoutOut = nil
//        }
//        return (maskResult, maskArray, layoutOut)
//    }
//
//    func binaryMask256ForClassifier(fromRawOutput mask: MLMultiArray) throws -> MLMultiArray {
//        try toBinaryMask256(mask)
//    }
//
//    func etalonAlignedBinaryMask256(fromBinary256 mask: MLMultiArray, letterboxLayout: LetterboxLayout) throws -> MLMultiArray {
//        let W = letterboxLayout.originalWidth
//        let H = letterboxLayout.originalHeight
//        guard W > 0, H > 0 else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        if W == DeepLabConfig.size, H == DeepLabConfig.size {
//            return mask
//        }
//
//        let img256 = binaryMask(from: mask)
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = 1
//        format.opaque = true
//
//        let upsampled = UIGraphicsImageRenderer(size: CGSize(width: W, height: H), format: format).image { ctx in
//            ctx.cgContext.interpolationQuality = .medium
//            img256.draw(in: CGRect(x: 0, y: 0, width: W, height: H))
//        }
//
//        let side = CGFloat(DeepLabConfig.size)
//        let resized = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { ctx in
//            ctx.cgContext.interpolationQuality = .none
//            upsampled.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
//        }
//
//        return try binaryMask256FromGrayUIImageForClassifier(resized)
//    }
//
//    private func binaryMask256FromGrayUIImageForClassifier(_ image: UIImage) throws -> MLMultiArray {
//        guard let cg = image.cgImage else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        let w = cg.width
//        let h = cg.height
//        guard w == DeepLabConfig.size, h == DeepLabConfig.size else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        guard let colorSpace = CGColorSpace(name: CGColorSpace.linearGray) ?? CGColorSpace(name: CGColorSpace.genericGrayGamma2_2) else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        var gray = [UInt8](repeating: 0, count: w * h)
//        guard let ctx = CGContext(
//            data: &gray,
//            width: w,
//            height: h,
//            bitsPerComponent: 8,
//            bytesPerRow: w,
//            space: colorSpace,
//            bitmapInfo: CGImageAlphaInfo.none.rawValue
//        ) else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        ctx.interpolationQuality = .none
//        ctx.translateBy(x: 0, y: CGFloat(h))
//        ctx.scaleBy(x: 1, y: -1)
//        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
//
//        let out = try MLMultiArray(shape: [1, 1, NSNumber(value: h), NSNumber(value: w)], dataType: .float32)
//        let t = DeepLabConfig.maskThreshold
//        for y in 0..<h {
//            for x in 0..<w {
//                let v = Float(gray[y * w + x]) / 255.0
//                let prob = min(max(v, 0), 1)
//                out[[0, 0, y, x] as [NSNumber]] = NSNumber(value: prob > t ? Float(1) : Float(0))
//            }
//        }
//        return out
//    }
//
//    func binaryMask(from multiArray: MLMultiArray, threshold: Float = 0.5) -> UIImage {
//        let height = DeepLabConfig.size
//        let width = DeepLabConfig.size
//        let shape = multiArray.shape.map { $0.intValue }
//        let strides = multiArray.strides.map { $0.intValue }
//        guard shape.count >= 2, shape.count == strides.count else {
//            return UIImage()
//        }
//        let mh = shape[shape.count - 2]
//        let mw = shape[shape.count - 1]
//        guard mh == height, mw == width else {
//            return UIImage()
//        }
//
//        var pixels = [UInt8](repeating: 0, count: width * height)
//        for y in 0..<height {
//            for x in 0..<width {
//                var idx = Array(repeating: 0, count: shape.count)
//                idx[shape.count - 2] = y
//                idx[shape.count - 1] = x
//                let o = mlaLinearOffset(strides: strides, indices: idx)
//                let v = mlaReadFloat(multiArray, linear: o)
//                let p = min(max(v, 0), 1)
//                pixels[y * width + x] = p > threshold ? 255 : 0
//            }
//        }
//
//        let cfData = CFDataCreate(nil, pixels, pixels.count)!
//        let provider = CGDataProvider(data: cfData)!
//
//        let cgImage = CGImage(
//            width: width,
//            height: height,
//            bitsPerComponent: 8,
//            bitsPerPixel: 8,
//            bytesPerRow: width,
//            space: CGColorSpaceCreateDeviceGray(),
//            bitmapInfo: CGBitmapInfo(rawValue: 0),
//            provider: provider,
//            decode: nil,
//            shouldInterpolate: false,
//            intent: .defaultIntent
//        )!
//
//        return UIImage(cgImage: cgImage)
//    }
//    
//    private func convertMultiArrayToMask(_ array: MLMultiArray) -> UIImage {
//        guard array.dataType == .float32 || array.dataType == .double else {
//            return UIImage()
//        }
//        let shape = array.shape.map { $0.intValue }
//        let strides = array.strides.map { $0.intValue }
//        guard shape.count >= 2, shape.count == strides.count else {
//            return UIImage()
//        }
//        let h = shape[shape.count - 2]
//        let w = shape[shape.count - 1]
//        guard h > 0, w > 0 else {
//            return UIImage()
//        }
//        let spatial = h * w
//        let total = array.count
//        guard total % spatial == 0 else {
//            return UIImage()
//        }
//        let groups = total / spatial
//
//        func indicesYX(_ y: Int, _ x: Int) -> [Int] {
//            var idx = Array(repeating: 0, count: shape.count)
//            idx[shape.count - 2] = y
//            idx[shape.count - 1] = x
//            return idx
//        }
//
//        let colorSpace = DeepLabColorSpace.sRGBOrFallback
//        let bytesPerPixel = 4
//        let bytesPerRow = bytesPerPixel * w
//        var raw = [UInt8](repeating: 0, count: h * bytesPerRow)
//
//        func writePixel(_ y: Int, _ x: Int, white: Bool) {
//            let c: UInt8 = white ? 255 : 0
//            let row = y
//            let o = row * bytesPerRow + x * bytesPerPixel
//            raw[o] = c
//            raw[o + 1] = c
//            raw[o + 2] = c
//            raw[o + 3] = 255
//        }
//
//        if groups == 1 {
//            for y in 0..<h {
//                for x in 0..<w {
//                    let v = mlaReadFloat(array, linear: mlaLinearOffset(strides: strides, indices: indicesYX(y, x)))
//                    let p = min(max(v, 0), 1)
//                    writePixel(y, x, white: p > 0.5)
//                }
//            }
//        } else if shape.count == 4, shape[0] == 1, shape[1] == groups {
//            let cCount = shape[1]
//            for y in 0..<h {
//                for x in 0..<w {
//                    var bestIdx = 0
//                    var bestVal = -Float.infinity
//                    for c in 0..<cCount {
//                        let lin = mlaLinearOffset(strides: strides, indices: [0, c, y, x])
//                        let v = mlaReadFloat(array, linear: lin)
//                        let s = maskSigmoid(v)
//                        if s > bestVal {
//                            bestVal = s
//                            bestIdx = c
//                        }
//                    }
//                    writePixel(y, x, white: bestIdx != 0)
//                }
//            }
//        } else if shape.count == 3, shape[0] == groups {
//            let cCount = shape[0]
//            for y in 0..<h {
//                for x in 0..<w {
//                    var bestIdx = 0
//                    var bestVal = -Float.infinity
//                    for c in 0..<cCount {
//                        let lin = mlaLinearOffset(strides: strides, indices: [c, y, x])
//                        let v = mlaReadFloat(array, linear: lin)
//                        let s = maskSigmoid(v)
//                        if s > bestVal {
//                            bestVal = s
//                            bestIdx = c
//                        }
//                    }
//                    writePixel(y, x, white: bestIdx != 0)
//                }
//            }
//        } else {
//            return UIImage()
//        }
//
//        guard let outCtx = CGContext(
//            data: &raw,
//            width: w,
//            height: h,
//            bitsPerComponent: 8,
//            bytesPerRow: bytesPerRow,
//            space: colorSpace,
//            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
//        ),
//              let outCg = outCtx.makeImage() else {
//            return UIImage()
//        }
//        return UIImage(cgImage: outCg, scale: 1, orientation: .up)
//    }
//    
//    private func cgImageUsesAlphaChannel(_ cg: CGImage) -> Bool {
//        switch cg.alphaInfo {
//        case .none, .noneSkipFirst, .noneSkipLast:
//            return false
//        default:
//            return true
//        }
//    }
//
//    private func uiImageStrippingAlphaChannel(_ image: UIImage) -> UIImage {
//        guard let cg = image.cgImage, cgImageUsesAlphaChannel(cg) else {
//            return image
//        }
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = image.scale
//        format.opaque = true
//        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
//        return renderer.image { ctx in
//            UIColor.white.setFill()
//            ctx.fill(CGRect(origin: .zero, size: image.size))
//            image.draw(in: CGRect(origin: .zero, size: image.size))
//        }
//    }
//
//    private func uiImagePreparedForDeepLabInference(_ image: UIImage) -> UIImage {
//        let oriented = image.normalizedDeepLabOrientation()
//        return uiImageStrippingAlphaChannel(oriented)
//    }
//    
//    private func resizeStretch256(prepared: UIImage, cgImage: CGImage) throws -> Letterbox256 {
//        let wpx = DeepLabConfig.size
//        let hpx = DeepLabConfig.size
//        let t = CGFloat(wpx)
//        let layout = LetterboxLayout(
//            originalWidth: cgImage.width,
//            originalHeight: cgImage.height,
//            contentRect256: CGRect(x: 0, y: 0, width: t, height: t),
//            displayPointSize: prepared.size,
//            displayScale: prepared.scale
//        )
//        let colorSpace = DeepLabColorSpace.sRGBOrFallback
//        let bytesPerPixel = 4
//        let bytesPerRow = bytesPerPixel * wpx
//        var raw = [UInt8](repeating: 0, count: hpx * bytesPerRow)
//        guard let ctx = CGContext(
//            data: &raw,
//            width: wpx,
//            height: hpx,
//            bitsPerComponent: 8,
//            bytesPerRow: bytesPerRow,
//            space: colorSpace,
//            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
//        ) else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        
//        ctx.interpolationQuality = .medium
//        ctx.translateBy(x: 0, y: CGFloat(hpx))
//        ctx.scaleBy(x: 1, y: -1)
//        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: t, height: t))
//        guard let outCg = ctx.makeImage() else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        let img = UIImage(cgImage: outCg, scale: 1, orientation: .up)
//        return Letterbox256(image: img, layout: layout)
//    }
//
//    // MARK: - NCHW tensor 0…255 float32
//    private func rgbNCHWFloatTensor(from256 cgImage: CGImage) throws -> MLMultiArray {
//        let w = cgImage.width
//        let h = cgImage.height
//        guard w == DeepLabConfig.size, h == DeepLabConfig.size else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        
//        let colorSpace = DeepLabColorSpace.sRGBOrFallback
//        let bytesPerPixel = 4
//        let bytesPerRow = bytesPerPixel * w
//        var raw = [UInt8](repeating: 0, count: h * bytesPerRow)
//        guard let ctx = CGContext(
//            data: &raw,
//            width: w,
//            height: h,
//            bitsPerComponent: 8,
//            bytesPerRow: bytesPerRow,
//            space: colorSpace,
//            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
//        ) else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        ctx.interpolationQuality = .none
//        ctx.translateBy(x: 0, y: CGFloat(h))
//        ctx.scaleBy(x: 1, y: -1)
//        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
//        
//        let multi = try MLMultiArray(shape: [1, 3, NSNumber(value: h), NSNumber(value: w)], dataType: .float32)
//        for y in 0..<h {
//            for x in 0..<w {
//                let o = y * bytesPerRow + x * bytesPerPixel
//                let r = Float(raw[o])
//                let g = Float(raw[o + 1])
//                let b = Float(raw[o + 2])
//                multi[[0, 0, y, x] as [NSNumber]] = NSNumber(value: r)
//                multi[[0, 1, y, x] as [NSNumber]] = NSNumber(value: g)
//                multi[[0, 2, y, x] as [NSNumber]] = NSNumber(value: b)
//            }
//        }
//        return multi
//    }
//
//    // MARK: - Mask postprocess
//    private func maskSigmoid(_ v: Float) -> Float {
//        let z = max(-40, min(40, v))
//        return 1 / (1 + exp(-z))
//    }
//
//    private func mlaLinearOffset(strides: [Int], indices: [Int]) -> Int {
//        var o = 0
//        for i in indices.indices {
//            o += indices[i] * strides[i]
//        }
//        return o
//    }
//
//    private func mlaReadFloat(_ array: MLMultiArray, linear: Int) -> Float {
//        let raw = UnsafeMutableRawPointer(array.dataPointer)
//        switch array.dataType {
//        case .float32:
//            return raw.bindMemory(to: Float.self, capacity: array.count)[linear]
//        case .double:
//            return Float(raw.bindMemory(to: Double.self, capacity: array.count)[linear])
//        default:
//            return 0
//        }
//    }
//
//    private func toBinaryMask256(_ mask: MLMultiArray) throws -> MLMultiArray {
//        let h = DeepLabConfig.size
//        let w = DeepLabConfig.size
//        let shape = mask.shape.map { $0.intValue }
//        guard shape.count >= 2 else {
//            throw DeepLabSegmentationError.unexpectedMaskShape(mask.shape)
//        }
//        let mh = shape[shape.count - 2]
//        let mw = shape[shape.count - 1]
//        guard mh == h, mw == w else {
//            throw DeepLabSegmentationError.unexpectedMaskShape(mask.shape)
//        }
//        
//        let out = try MLMultiArray(shape: [1, 1, NSNumber(value: h), NSNumber(value: w)], dataType: .float32)
//        
//        let strides = mask.strides.map { $0.intValue }
//        guard strides.count == shape.count else {
//            throw DeepLabSegmentationError.unexpectedMaskShape(mask.shape)
//        }
//        
//        let t = DeepLabConfig.maskThreshold
//        for y in 0..<h {
//            for x in 0..<w {
//                var idx = Array(repeating: 0, count: shape.count)
//                idx[shape.count - 2] = y
//                idx[shape.count - 1] = x
//                let o = mlaLinearOffset(strides: strides, indices: idx)
//                let raw = mlaReadFloat(mask, linear: o)
//                let prob = min(max(raw, 0), 1)
//                out[[0, 0, y, x] as [NSNumber]] = NSNumber(value: prob > t ? Float(1) : Float(0))
//            }
//        }
//        return out
//    }
//
//    func binaryMaskUIImage(fromBinaryMask256 mask: MLMultiArray) throws -> UIImage {
//        let h = DeepLabConfig.size
//        let w = DeepLabConfig.size
//        let shape = mask.shape.map { $0.intValue }
//        guard shape == [1, 1, h, w] else {
//            throw DeepLabSegmentationError.unexpectedMaskShape(mask.shape)
//        }
//        
//        let colorSpace = DeepLabColorSpace.sRGBOrFallback
//        let bytesPerPixel = 4
//        let bytesPerRow = bytesPerPixel * w
//        var raw = [UInt8](repeating: 0, count: h * bytesPerRow)
//        
//        for y in 0..<h {
//            for x in 0..<w {
//                let v = Float(truncating: mask[[0, 0, y, x] as [NSNumber]])
//                let c: UInt8 = v > 0.5 ? 255 : 0
//                let o = y * bytesPerRow + x * bytesPerPixel
//                raw[o] = c
//                raw[o + 1] = c
//                raw[o + 2] = c
//                raw[o + 3] = 255
//            }
//        }
//        
//        guard let outCtx = CGContext(
//            data: &raw,
//            width: w,
//            height: h,
//            bitsPerComponent: 8,
//            bytesPerRow: bytesPerRow,
//            space: colorSpace,
//            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
//        ),
//              let outCg = outCtx.makeImage() else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        return UIImage(cgImage: outCg, scale: 1, orientation: .up)
//    }
//
//
//    func binaryMaskUIImage(fromBinaryMask256 mask: MLMultiArray, letterboxLayout: LetterboxLayout) throws -> UIImage {
//        let mask256 = try binaryMaskUIImage(fromBinaryMask256: mask)
//        guard let cg256 = mask256.cgImage else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        let canvas = CGFloat(DeepLabConfig.size)
//        let bounds = CGRect(x: 0, y: 0, width: canvas, height: canvas)
//        let crop = letterboxLayout.contentRect256.integral.intersection(bounds)
//        guard crop.width >= 1, crop.height >= 1 else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        guard let croppedCg = cg256.cropping(to: crop) else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        let ow = letterboxLayout.originalWidth
//        let oh = letterboxLayout.originalHeight
//        guard ow > 0, oh > 0 else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        let outSize = letterboxLayout.displayPointSize
//        guard outSize.width > 0, outSize.height > 0 else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = letterboxLayout.displayScale
//        format.opaque = true
//        let renderer = UIGraphicsImageRenderer(size: outSize, format: format)
//        return renderer.image { ctx in
//            UIColor.black.setFill()
//            ctx.fill(CGRect(origin: .zero, size: outSize))
//            ctx.cgContext.interpolationQuality = .medium
//            let cropped = UIImage(cgImage: croppedCg, scale: 1, orientation: .up)
//            cropped.draw(in: CGRect(origin: .zero, size: outSize))
//        }
//    }
//    
//    
//    
//}






extension CGImage {
  // Creates a new CGImage from a CVPixelBuffer
  public static func create(pixelBuffer: CVPixelBuffer) -> CGImage? {
    var cgImage: CGImage?
    VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
    return cgImage
  }

  /*
  // Alternative implementation:
  public static func create(pixelBuffer: CVPixelBuffer) -> CGImage? {
    // This method creates a bitmap CGContext using the pixel buffer's memory.
    // It currently only handles kCVPixelFormatType_32ARGB images. To support
    // other pixel formats too, you'll have to change the bitmapInfo and maybe
    // the color space for the CGContext.

    guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly) else {
      return nil
    }
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

    if let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                               width: CVPixelBufferGetWidth(pixelBuffer),
                               height: CVPixelBufferGetHeight(pixelBuffer),
                               bitsPerComponent: 8,
                               bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                               space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue),
       let cgImage = context.makeImage() {
      return cgImage
    } else {
      return nil
    }
  }
  */

  /**
   Creates a new CGImage from a CVPixelBuffer, using Core Image.
  */
  public static func create(pixelBuffer: CVPixelBuffer, context: CIContext) -> CGImage? {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let rect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer),
                                  height: CVPixelBufferGetHeight(pixelBuffer))
    return context.createCGImage(ciImage, from: rect)
  }
}


