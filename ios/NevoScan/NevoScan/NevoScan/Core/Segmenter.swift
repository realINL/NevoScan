//
//  Segmenter.swift
//  NevoScan
//
//  Created by Илья Лебедев on 10.05.2026.
//

import Foundation
import CoreML
import UIKit

class SegmenterImageType: SegmenterProtocol {
    
    private let model: MLModel
    private let segmenter: SegmentationModel
    
    init() throws {
        
        do {
            let modelConfiguration = MLModelConfiguration()
            let model = try SegmentationModel(configuration: modelConfiguration)
            self.segmenter = model
            self.model = model.model
        } catch {
            throw SegmentationError.modelLoadingError
        }
    }
    
    
    func runSegmentation(on image: UIImage) async throws -> (maskResult: UIImage, maskArray: MLMultiArray) {
        guard let imageBuffer = image.pixelBuffer(width: 256, height: 256) else {
            throw SegmentationError.couldNotPrepareImage
        }
        
        let originalImageSize = image.size
        
        guard let result = try? segmenter.prediction(image: imageBuffer) else { throw SegmentationError.predictionFailed}
        
        let maskArray = result.segmentation_mask
        guard let maskImage = try? maskUIImageResized(from: maskArray, targetSize: originalImageSize) else {
            throw SegmentationError.missingOutput("maskImage")
        }
        
        return (maskImage, maskArray)
    }
    

    func makeMaskUIImage(from mask: MLMultiArray) throws -> UIImage {
        let threshold = Float(0.5)
        let shape = mask.shape.map { $0.intValue }

        guard shape == [1, 1, 256, 256] else {
            throw SegmentationError.unexpectedMaskShape(shape)
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
            throw SegmentationError.cgImageCreationFailed
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
            throw SegmentationError.cgImageCreationFailed
        }

        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }
    
    func maskUIImageResized(
        from mask: MLMultiArray,
        targetSize: CGSize
    ) throws -> UIImage {

        let threshold = Float(0.5)
        // 1. Получаем 256×256 пиксели
        let width = mask.shape[3].intValue 
        let height = mask.shape[2].intValue

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


enum SegmentationError: LocalizedError {
    case modelLoadingError
    case predictionFailed
    case couldNotPrepareImage
    case missingOutput(String)
    case unexpectedMaskShape([Int])
    case cgImageCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .modelLoadingError:
            return "Модель сегментации не найдена в приложении."
        case .predictionFailed:
            return "Не удалось выполнить предсказание"
        case .couldNotPrepareImage:
            return "Не удалось подготовить изображение для сегментации"
        case .missingOutput(let name):
            return "Нет выхода модели: \(name)"
        case .unexpectedMaskShape(let s):
            return "Неожиданная форма маски: \(s.map { $0})"
        case .cgImageCreationFailed:
            return "Не удадось создатьcCgImage"
        }
    }
}
