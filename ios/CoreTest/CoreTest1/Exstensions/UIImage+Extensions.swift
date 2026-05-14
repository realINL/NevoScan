//
//  UIImage+Extensions.swift
//  NevoScan
//
//  Created by Илья Лебедев on 12.03.2026.
//

import UIKit

//extension UIImage {
//    func normalizedUp() -> UIImage {
//        guard imageOrientation != .up else { return self }
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = scale
//        let renderer = UIGraphicsImageRenderer(size: size, format: format)
//        return renderer.image { _ in
//            draw(in: CGRect(origin: .zero, size: size))
//        }
//    }
//
//    func resized256() -> UIImage? {
//        let target = CGSize(width: ResNetFeatMaskConfig.size, height: ResNetFeatMaskConfig.size)
//        let format = UIGraphicsImageRendererFormat()
//        format.scale = 1
//        format.opaque = true
//        let renderer = UIGraphicsImageRenderer(size: target, format: format)
//        return renderer.image { _ in
//            draw(in: CGRect(origin: .zero, size: target))
//        }
//    }
//
//    func toPixelBuffer256() -> CVPixelBuffer? {
//        guard let cgImage = cgImage else { return nil }
//        let w = ResNetFeatMaskConfig.size
//        let h = ResNetFeatMaskConfig.size
//        var pxbuffer: CVPixelBuffer?
//        let attrs: [CFString: Any] = [
//            kCVPixelBufferCGImageCompatibilityKey: true,
//            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
//        ]
//        let status = CVPixelBufferCreate(
//            kCFAllocatorDefault,
//            w,
//            h,
//            kCVPixelFormatType_32BGRA,
//            attrs as CFDictionary,
//            &pxbuffer
//        )
//        guard status == kCVReturnSuccess, let buffer = pxbuffer else { return nil }
//
//        CVPixelBufferLockBaseAddress(buffer, [])
//        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
//        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else { return nil }
//
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        guard let ctx = CGContext(
//            data: baseAddress,
//            width: w,
//            height: h,
//            bitsPerComponent: 8,
//            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
//            space: colorSpace,
//            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
//        ) else { return nil }
//
//        ctx.interpolationQuality = .high
//        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))
//        return buffer
//    }
//}

//extension CGImage {
//    func rgbToBgr(data: inout [UInt8]) {
//        for i in stride(from: 0, to: data.count, by: 3) {
//            (data[i], data[i + 2]) = (data[i + 2], data[i])
//        }
//    }
//}
