//
//  Classifier.swift
//  NevoScan
//
//  Created by Илья Лебедев on 10.05.2026.
//

import Foundation
import UIKit
import CoreML

class Classifier: ClassifierProtocol {
    

    private let classifier: ResNetFeatMask

    init() throws {
        let configuration: MLModelConfiguration = MLModelConfiguration()
        self.classifier = try ResNetFeatMask(configuration: configuration)
    }


    func probabilities(image: UIImage, mask: MLMultiArray) throws -> (benign: Double, malign: Double) {

        guard let imageBuffer = image.pixelBuffer(width: 256, height: 256) else {
            throw ResNetFeatMaskError.couldNotPrepareImage
        }


        let output = try classifier.prediction(
            image: imageBuffer,
            seg_mask: mask
        )

        let arr = output.probs.toFloatArray()
        
        let mal = Double(arr[0])
        let ben = Double(arr[1])
        
        return (mal, ben)
    }

    /// Resize((8,8))
    private func makeMask8(from segmentationOutput: MLMultiArray) throws -> MLMultiArray {
        guard segmentationOutput.shape.map(\.intValue) == [1, 1, 256, 256] else {
            throw ClassificationError.invalidSegmentationShape(segmentationOutput.shape)
        }

        let mask8 = try MLMultiArray(
            shape: [1, 1, 8, 8],
            dataType: .float32
        )

        let inputPtr = segmentationOutput.dataPointer.assumingMemoryBound(to: Float32.self)
        let outputPtr = mask8.dataPointer.assumingMemoryBound(to: Float32.self)

        let inStrideN = segmentationOutput.strides[0].intValue
        let inStrideC = segmentationOutput.strides[1].intValue
        let inStrideH = segmentationOutput.strides[2].intValue
        let inStrideW = segmentationOutput.strides[3].intValue

        let outStrideN = mask8.strides[0].intValue
        let outStrideC = mask8.strides[1].intValue
        let outStrideH = mask8.strides[2].intValue
        let outStrideW = mask8.strides[3].intValue

        for y in 0..<8 {
            for x in 0..<8 {
                // nearest downsample 256 -> 8
                let srcY = y * 32
                let srcX = x * 32

                let inputOffset =
                    0 * inStrideN +
                    0 * inStrideC +
                    srcY * inStrideH +
                    srcX * inStrideW

                let outputOffset =
                    0 * outStrideN +
                    0 * outStrideC +
                    y * outStrideH +
                    x * outStrideW

                let probability = inputPtr[inputOffset]

                outputPtr[outputOffset] = probability > 0.5 ? 1.0 : 0.0
            }
        }
        printMask8(mask8)
        return mask8
    }
    
    func printMask8(_ mask: MLMultiArray) {
        print("============================")
        let ptr = mask.dataPointer.assumingMemoryBound(to: Float32.self)

        let s0 = mask.strides[0].intValue
        let s1 = mask.strides[1].intValue
        let s2 = mask.strides[2].intValue
        let s3 = mask.strides[3].intValue

        for y in 0..<8 {
            var row: [String] = []

            for x in 0..<8 {
                let offset = 0 * s0 + 0 * s1 + y * s2 + x * s3
                row.append(String(format: "%.0f", ptr[offset]))
            }

            print(row.joined(separator: " "))
        }
    }
}

extension MLMultiArray {
    func toFloatArray() -> [Float] {
        let count = self.count

        switch self.dataType {
        case .float32:
            let ptr = self.dataPointer.assumingMemoryBound(to: Float32.self)
            return (0..<count).map { Float(ptr[$0]) }

        case .double:
            let ptr = self.dataPointer.assumingMemoryBound(to: Double.self)
            return (0..<count).map { Float(ptr[$0]) }

        case .float16:
            // На всякий случай fallback через NSNumber
            return (0..<count).map { self[$0].floatValue }

        default:
            return (0..<count).map { self[$0].floatValue }
        }
    }
}

enum ClassificationError: Error {
    case failedToCreatePixelBuffer
    case invalidSegmentationShape([NSNumber])
}
