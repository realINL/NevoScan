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
import YOLO

class Detector2 {
    var model: YOLO
    
    init() {
        self.model = YOLO("best", task: .detect)
    }
    
    func detectMole(on image: UIImage) throws -> (crop: UIImage, annotaion: UIImage) {
        let result = model(image)
        guard !result.boxes.isEmpty else { throw DetectorErrors.notFound}
        
        guard let croppedImage = cropImage(image: image, result: result) else {
            throw DetectorErrors.croppingError
        }
        
        guard let annotatedImage = drawBox(image: image, result: result) else {
            throw DetectorErrors.drawingError
        }
        
        return(croppedImage, annotatedImage)
        
    }
    
    // MARK: Cropping image to detected box
    private func cropImage(image: UIImage, result: YOLOResult) -> UIImage? {
        let cgImage = image.cgImage
        let rect = result.boxes.first!.xywh
        
        if let croppedImage = cgImage?.cropping(to: rect) {
            return UIImage(cgImage: croppedImage)
        } else {
            return nil
        }
    }
    
    // MARK: Drawing box
    /// Drawing box of detected mole
    private func drawBox(image: UIImage, result: YOLOResult) -> UIImage? {
        let box = result.boxes.first!
        guard let ciImage = CIImage(image: image) else { return nil }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return UIImage()
        }
        let width = cgImage.width
        let height = cgImage.height
        let imageSize = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let drawContext = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return UIImage()
        }
        drawContext.saveGState()
        drawContext.translateBy(x: 0, y: CGFloat(height))
        drawContext.scaleBy(x: 1, y: -1)
        drawContext.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))
        drawContext.restoreGState()
        
        let rect = box.xywh
        
        // Затеменеие
        let fullPath = UIBezierPath(rect: CGRect(origin: .zero, size: image.size))
        let rectPath = UIBezierPath(rect: rect)
        
        fullPath.append(rectPath)
        fullPath.usesEvenOddFillRule = true
        
        drawContext.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
        fullPath.fill()
        
        // Выделение
        let lineWidth = 10
        let color = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 15)
        drawContext.setStrokeColor(color)
        drawContext.setLineWidth(CGFloat(lineWidth))
        drawContext.addPath(path.cgPath)
        drawContext.strokePath()
        
        
        let drawnImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return drawnImage
    }
    
    
}

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
