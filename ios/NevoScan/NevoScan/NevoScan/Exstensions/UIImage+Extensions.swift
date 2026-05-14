//
//  UIImage+Extensions.swift
//  NevoScan
//
//  Created by Илья Лебедев on 09.05.2026.
//

import UIKit

extension UIImage {
    func normalizedDeepLabOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

  // Converts the image to an ARGB CVPixelBuffer
  public func pixelBuffer() -> CVPixelBuffer? {
    return pixelBuffer(width: Int(size.width), height: Int(size.height))
  }

  // Resizes the image to width x height and converts it to an ARGB CVPixelBuffer
  public func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
    return pixelBuffer(width: width, height: height,
                       pixelFormatType: kCVPixelFormatType_32ARGB,
                       colorSpace: CGColorSpaceCreateDeviceRGB(),
                       alphaInfo: .noneSkipFirst)
  }

  // Converts the image to a grayscale CVPixelBuffer
  public func pixelBufferGray() -> CVPixelBuffer? {
    return pixelBufferGray(width: Int(size.width), height: Int(size.height))
  }

  // Resizes the image to width x height and converts it to a grayscale CVPixelBuffer
  public func pixelBufferGray(width: Int, height: Int) -> CVPixelBuffer? {
    return pixelBuffer(width: width, height: height,
                       pixelFormatType: kCVPixelFormatType_OneComponent8,
                       colorSpace: CGColorSpaceCreateDeviceGray(),
                       alphaInfo: .none)
  }

  // Resizes the image to width x height and converts it to a CVPixelBuffer with the specified pixel format, color space, and alpha channel
  public func pixelBuffer(width: Int, height: Int,
                          pixelFormatType: OSType,
                          colorSpace: CGColorSpace,
                          alphaInfo: CGImageAlphaInfo) -> CVPixelBuffer? {
    var maybePixelBuffer: CVPixelBuffer?
    let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                 kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     width,
                                     height,
                                     pixelFormatType,
                                     attrs as CFDictionary,
                                     &maybePixelBuffer)

    guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
      return nil
    }

    let flags = CVPixelBufferLockFlags(rawValue: 0)
    guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
      return nil
    }
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, flags) }

    guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                  space: colorSpace,
                                  bitmapInfo: alphaInfo.rawValue)
    else {
      return nil
    }

    UIGraphicsPushContext(context)
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
    UIGraphicsPopContext()

    return pixelBuffer
  }

  // Creates a new UIImage from a CVPixelBuffer
  public convenience init?(pixelBuffer: CVPixelBuffer) {
    if let cgImage = CGImage.create(pixelBuffer: pixelBuffer) {
      self.init(cgImage: cgImage)
    } else {
      return nil
    }
  }


  // Creates a new UIImage from a CVPixelBuffer, using a Core Image context.
  public convenience init?(pixelBuffer: CVPixelBuffer, context: CIContext) {
    if let cgImage = CGImage.create(pixelBuffer: pixelBuffer, context: context) {
      self.init(cgImage: cgImage)
    } else {
      return nil
    }
  }
    
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
    
    private func cgClassifierHasAlpha(_ cg: CGImage) -> Bool {
        switch cg.alphaInfo {
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        default:
            return true
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

