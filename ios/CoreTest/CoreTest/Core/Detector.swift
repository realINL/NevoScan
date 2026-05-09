//
//  Detecor.swift
//  NevoScan
//
//  Created by Илья Лебедев on 11.03.2026.
//

import Foundation
import CoreML
import UIKit
import Vision



struct Box: @unchecked Sendable {
    /// The index of the class in the model's class list.
    public let index: Int
    
    /// The class label (category name) of the detected object.
    public let cls: String
    
    /// The confidence score (0.0 to 1.0) for the detection.
    public let conf: Float
    
    /// The bounding box in image coordinates (x, y, width, height).
    public let xywh: CGRect
    
    /// The bounding box in normalized coordinates (0.0 to 1.0).
    public let xywhn: CGRect
}

//extension UIImage {
//    public func transformToDetect() -> CVPixelBuffer? {
//        self.cgImage?.createPixelBuffer(width: 640, height: 640)
//    }
//}
//extension CGImage {
//    public func createPixelBuffer() -> CVPixelBuffer? {
//        return pixelBuffer(width: width, height: height, orientation: .up)
//        
//    }
//    public func createPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
//        return pixelBuffer(width: width, height: height, orientation: .up)
//        
//    }
//    
//    private func pixelBuffer(width: Int, height: Int,
//                             orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
//        return pixelBuffer(width: width, height: height,
//                           pixelFormatType: kCVPixelFormatType_32ARGB,
//                           colorSpace: CGColorSpaceCreateDeviceRGB(),
//                           alphaInfo: .noneSkipFirst,
//                           orientation: orientation)
//    }
//    private func pixelBuffer(width: Int, height: Int,
//                             pixelFormatType: OSType,
//                             colorSpace: CGColorSpace,
//                             alphaInfo: CGImageAlphaInfo,
//                             orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
//        
//        // TODO: If the orientation is not .up, then rotate the CGImage.
//        // See also: https://stackoverflow.com/a/40438893/
//        
//        assert(orientation == .up)
//        
//        var maybePixelBuffer: CVPixelBuffer?
//        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
//             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
//        let status = CVPixelBufferCreate(kCFAllocatorDefault,
//                                         width,
//                                         height,
//                                         pixelFormatType,
//                                         attrs as CFDictionary,
//                                         &maybePixelBuffer)
//        
//        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
//            return nil
//        }
//        
//        let flags = CVPixelBufferLockFlags(rawValue: 0)
//        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
//            return nil
//        }
//        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, flags) }
//        
//        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
//                                      width: width,
//                                      height: height,
//                                      bitsPerComponent: 8,
//                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
//                                      space: colorSpace,
//                                      bitmapInfo: alphaInfo.rawValue)
//        else {
//            return nil
//        }
//        
//        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
//        return pixelBuffer
//    }
//    
//}
