//
//  Segmenter.swift
//  CoreTest
//
//  Created by Илья Лебедев on 14.05.2026.
//

import Foundation
import CoreML
import UIKit

class SegmenterImageType: SegmenterProtocol {
    
    private let model: MLModel
    private let segmenter: SegmentationModel
    
    init() throws {
        
        do {
//            let ml = try MLModel(contentsOf: url)
            let modelConfiguration = MLModelConfiguration()
            let model = try  SegmentationModel(configuration: modelConfiguration)
            self.segmenter = model
            self.model = model.model
        } catch {
            throw CoreEngineErrors.failureLoadSegmenter
        }
    }
    
    
    func runSegmentation(on image: UIImage) async  -> (maskResult: UIImage?, maskArray: MLMultiArray?) {
        guard let imageBuffer = image.pixelBuffer(width: 256, height: 256) else {
            print(DeepLabSegmentationError.couldNotPrepareImage)
            return (nil, nil)
        }
        let originalImageSize = image.size
        
        guard let result = try? segmenter.prediction(image: imageBuffer) else { return (nil, nil)}
        
        let maskArray = result.segmentation_mask
//        let maskImage = try? makeMaskUIImage(from: maskArray)
        let maskImage = try? maskUIImageResized(from: maskArray, targetSize: originalImageSize)
        
        return (maskImage, maskArray)
        
        
    }
    
    func binaryMask256ForClassifier(fromRawOutput mask: MLMultiArray) throws -> MLMultiArray {
        return mask
    }
    
    private enum DeepLabColorSpace {
        static let sRGBOrFallback: CGColorSpace = {
            if let srgb = CGColorSpace(name: CGColorSpace.sRGB) {
                return srgb
            }
            return CGColorSpaceCreateDeviceRGB()
        }()
    }
    
//    func binaryMaskUIImage(fromBinaryMask256 mask: MLMultiArray) throws -> UIImage {
//        let h = 256
//        let w = 256
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
//                // CGBitmap: строка 0 памяти = низ изображения; индекс [*, y, x] в NCHW — верх.
//                let bufRow = h - 1 - y
//                let o = bufRow * bytesPerRow + x * bytesPerPixel
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
//    private func toBinaryMask256(_ mask: MLMultiArray) throws -> MLMultiArray {
//        let h = 256
//        let w = 256
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
//        let t = Float(0.5)
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
//    func binaryMaskUIImage(fromBinaryMask256 mask: MLMultiArray, letterboxLayout: LetterboxLayout) throws -> UIImage {
//        let mask256 = try binaryMaskUIImage(fromBinaryMask256: mask)
//        guard let cg256 = mask256.cgImage else {
//            throw DeepLabSegmentationError.couldNotPrepareImage
//        }
//        let canvas = CGFloat(256)
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
    
    enum MaskImageError: Error {
        case invalidShape
        case cgImageCreationFailed
    }

    func makeMaskUIImage(from mask: MLMultiArray) throws -> UIImage {
        let threshold = Float(0.5)
        let shape = mask.shape.map { $0.intValue }

        guard shape == [1, 1, 256, 256] else {
            throw MaskImageError.invalidShape
        }

        let width = 256
        let height = 256

        let ptr = mask.dataPointer.assumingMemoryBound(to: Float32.self)

        let strideN = mask.strides[0].intValue
        let strideC = mask.strides[1].intValue
        let strideH = mask.strides[2].intValue
        let strideW = mask.strides[3].intValue

        var pixels = [UInt8](repeating: 0, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let offset =
                    0 * strideN +
                    0 * strideC +
                    y * strideH +
                    x * strideW

                let value = ptr[offset]

                let pixel: UInt8

               
                pixel = value > threshold ? 255 : 0
                

                pixels[y * width + x] = pixel
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceGray()

        guard let provider = CGDataProvider(
            data: Data(pixels) as CFData
        ) else {
            throw MaskImageError.cgImageCreationFailed
        }

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw MaskImageError.cgImageCreationFailed
        }

        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }
    
    func maskUIImageResized(
        from mask: MLMultiArray,
        targetSize: CGSize
    ) throws -> UIImage {

        let threshold = Float(0.5)
        // 1. Получаем 256×256 пиксели
        let width = mask.shape[3].intValue   // 256
        let height = mask.shape[2].intValue  // 256

        let ptr = mask.dataPointer.assumingMemoryBound(to: Float32.self)
        let strideN = mask.strides[0].intValue
        let strideC = mask.strides[1].intValue
        let strideH = mask.strides[2].intValue
        let strideW = mask.strides[3].intValue

        var pixels = [UInt8](repeating: 0, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let offset = 0 * strideN + 0 * strideC + y * strideH + x * strideW
                let value = ptr[offset]
                let pixel: UInt8 = value > threshold ? 255 : 0
                pixels[y * width + x] = pixel
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceGray()

        guard let provider = CGDataProvider(data: Data(pixels) as CFData) else {
            throw NSError(domain: "Mask", code: -1)
        }

        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw NSError(domain: "Mask", code: -1)
        }

        let maskImage256 = UIImage(cgImage: cgImage)

        // 2. Resize до исходного размера
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        maskImage256.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedMask = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let finalMask = resizedMask else {
            throw NSError(domain: "Mask", code: -1)
        }

        return finalMask
    }
    
    
    
    
}
