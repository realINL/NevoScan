//
//  NevusYOLODetector.swift
//  NevoScan
//

import CoreGraphics
import CoreML
import Foundation
import UIKit
import Vision

enum NevusDetectionError: LocalizedError {
    case modelNotFound
    case predictionFailed(Error)
    case missingOutput(String)
    case invalidOutputShape([NSNumber])
    case noDetectionAboveThreshold
    case couldNotPrepareImage

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "Модель не найдена в приложении."
        case .predictionFailed(let e):
            return e.localizedDescription
        case .missingOutput(let name):
            return "Нет выхода модели: \(name)"
        case .invalidOutputShape(let s):
            return "Неожиданная форма выхода: \(s.map { $0.intValue })"
        case .noDetectionAboveThreshold:
            return "Объекты на изображении не найдены"
        case .couldNotPrepareImage:
            return "Не удалось обработать изображение"
        }
    }
}

/// Параметры как в `test.py`: imgsz=640, conf=0.4, iou=0.8 для NMS.
/// Letterbox как `LetterBox` в Ultralytics: padding 114, `round` размеров, отступы `round(dw±0.1)`.
enum YOLOConfig {
    static let inputSize: CGFloat = 640
    static let confidenceThreshold: Float = 0.4
    static let fallbackConfidenceThreshold: Float = 0.25
    static let nmsIoUThreshold: CGFloat = 0.8
    /// Сырой выход без NMS в экспорте Ultralytics.
    static let rawOutputName = "var_910"
    /// Имена выходов Core ML NMS pipeline (см. ultralytics `pipeline_coreml`).
    static let nmsCoordinatesName = "coordinates"
    static let nmsConfidenceName = "confidence"
    static let letterboxGray: CGFloat = 114 / 255
}

struct NevusYOLODetector {
    private let vnModel: VNCoreMLModel

    init(mlModel: MLModel) throws {
        self.vnModel = try VNCoreMLModel(for: mlModel)
    }

    static func loadBundled() throws -> NevusYOLODetector {
        let bundle = Bundle.main
        let candidates: [(String, String)] = [
            ("best", "mlmodelc"),
            ("best", "mlpackage"),
            ("model", "mlmodelc"),
            ("model", "mlpackage")
        ]
        for (name, ext) in candidates {
            if let url = bundle.url(forResource: name, withExtension: ext) {
                let ml = try MLModel(contentsOf: url)
                return try NevusYOLODetector(mlModel: ml)
            }
        }
        throw NevusDetectionError.modelNotFound
    }

    
    func cropNevus(from image: UIImage) throws -> (cropped: UIImage, score: Double) {
        let oriented = image.normalizedUpOrientation()
        guard let cgImage = oriented.cgImage else {
            throw NevusDetectionError.couldNotPrepareImage
        }

        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)

        let letter = try LetterboxResult.make(cgImage: cgImage, target: Int(YOLOConfig.inputSize))

        guard let letterCg = letter.image.cgImage else {
            throw NevusDetectionError.couldNotPrepareImage
        }

        let visionOut = try runVisionCoreML(letterCgImage: letterCg)

        let bestInLetterbox640: ScoredRect
        switch visionOut {
        case .recognizedObjects(let observations):
            guard let best = bestRecognizedBox(
                observations,
                thresholds: [YOLOConfig.confidenceThreshold, YOLOConfig.fallbackConfidenceThreshold]
            ) else {
                throw NevusDetectionError.noDetectionAboveThreshold
            }
            bestInLetterbox640 = best

        case .nmsFeatureArrays(let coordinates, let confidenceArray):
            var boxes = try boxesFromNMSFeatureArrays(
                coordinates: coordinates,
                confidenceArray: confidenceArray,
                threshold: YOLOConfig.confidenceThreshold
            )
            if boxes.isEmpty {
                boxes = try boxesFromNMSFeatureArrays(
                    coordinates: coordinates,
                    confidenceArray: confidenceArray,
                    threshold: YOLOConfig.fallbackConfidenceThreshold
                )
            }
            guard let best = boxes.max(by: { $0.score < $1.score }) else {
                throw NevusDetectionError.noDetectionAboveThreshold
            }
            bestInLetterbox640 = best

        case .rawMultiArray(let multi):
            var boxes = try bestDecodeBoxes(from: multi, confidenceThreshold: YOLOConfig.confidenceThreshold)
            if boxes.isEmpty {
                boxes = try bestDecodeBoxes(from: multi, confidenceThreshold: YOLOConfig.fallbackConfidenceThreshold)
            }
            guard !boxes.isEmpty else {
                throw NevusDetectionError.noDetectionAboveThreshold
            }
            let kept = nonMaxSuppression(boxes: boxes, iouThreshold: YOLOConfig.nmsIoUThreshold)
            guard let best = kept.first else {
                throw NevusDetectionError.noDetectionAboveThreshold
            }
            bestInLetterbox640 = best
        }

        let mapped = mapBoxToOriginal(
            bestInLetterbox640.rect,
            gain: letter.gain,
            padLeft: letter.padLeft,
            padTop: letter.padTop
        )

        let bounds = CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight)
        let cropRect = mapped.intersection(bounds).integral

        guard cropRect.width >= 2, cropRect.height >= 2,
              let croppedCg = cgImage.cropping(to: cropRect) else {
            throw NevusDetectionError.noDetectionAboveThreshold
        }

        let cropped = UIImage(cgImage: croppedCg, scale: oriented.scale, orientation: .up)
        return (cropped, bestInLetterbox640.score)
    }

    private enum VisionCoreMLResult {
        case recognizedObjects([VNRecognizedObjectObservation])
        case nmsFeatureArrays(coordinates: MLMultiArray, confidence: MLMultiArray)
        case rawMultiArray(MLMultiArray)
    }

    /// Инференс через Vision;
    private func runVisionCoreML(letterCgImage: CGImage) throws -> VisionCoreMLResult {
        var output: VisionCoreMLResult?
        var capturedError: Error?

        let request = VNCoreMLRequest(model: vnModel) { request, error in
            if let error {
                capturedError = error
                return
            }
            let results = request.results ?? []

            let recognized = results.compactMap { $0 as? VNRecognizedObjectObservation }
            if !recognized.isEmpty {
                output = .recognizedObjects(recognized)
                return
            }

            let features = results.compactMap { $0 as? VNCoreMLFeatureValueObservation }
            var byName: [String: MLFeatureValue] = [:]
            for f in features {
                byName[f.featureName] = f.featureValue
            }

            if let coord = byName[YOLOConfig.nmsCoordinatesName]?.multiArrayValue,
               let conf = byName[YOLOConfig.nmsConfidenceName]?.multiArrayValue {
                output = .nmsFeatureArrays(coordinates: coord, confidence: conf)
                return
            }

            if let m = features.first(where: { $0.featureName == YOLOConfig.rawOutputName })?.featureValue.multiArrayValue {
                output = .rawMultiArray(m)
                return
            }
            if let m = features.compactMap({ $0.featureValue.multiArrayValue }).first {
                output = .rawMultiArray(m)
                return
            }

            capturedError = NevusDetectionError.missingOutput("\(YOLOConfig.nmsCoordinatesName)/\(YOLOConfig.nmsConfidenceName) или \(YOLOConfig.rawOutputName)")
        }

        request.imageCropAndScaleOption = .scaleFit

        let handler = VNImageRequestHandler(cgImage: letterCgImage, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            throw NevusDetectionError.predictionFailed(error)
        }

        if let capturedError {
            throw capturedError
        }
        guard let out = output else {
            throw NevusDetectionError.noDetectionAboveThreshold
        }
        return out
    }
}

// MARK: - Core ML NMS outputs (coordinates + confidence)

/// Нормализованный bbox Vision → пиксели в полотне letterbox (начало координат сверху-слева, как в UIKit).
private func pixelRectInLetterbox(fromVisionNormalizedBox box: CGRect, letterExtent: CGFloat) -> CGRect {
    let w = box.width * letterExtent
    let h = box.height * letterExtent
    let x = box.origin.x * letterExtent
    let yTop = (1.0 - box.origin.y - box.height) * letterExtent
    return CGRect(x: x, y: yTop, width: w, height: h)
}

private func bestRecognizedBox(_ observations: [VNRecognizedObjectObservation], thresholds: [Float]) -> ScoredRect? {
    for t in thresholds {
        let t = Double(t)
        let candidates = observations
            .filter { Double($0.confidence) >= t }
            .sorted { $0.confidence > $1.confidence }
        guard let top = candidates.first else { continue }
        let rect = pixelRectInLetterbox(fromVisionNormalizedBox: top.boundingBox, letterExtent: YOLOConfig.inputSize)
        return ScoredRect(rect: rect, score: Double(top.confidence))
    }
    return nil
}

/// Парсинг парных массивов из NMS pipeline Ultralytics (нормализованные xywh относительно размера входа).
private func boxesFromNMSFeatureArrays(
    coordinates: MLMultiArray,
    confidenceArray: MLMultiArray,
    threshold: Float
) throws -> [ScoredRect] {
    let cShape = coordinates.shape.map { $0.intValue }
    let fShape = confidenceArray.shape.map { $0.intValue }

    let n: Int
    let coordBoxMajor: Bool

    if cShape.count == 3, cShape[0] == 1, cShape[2] == 4 {
        n = cShape[1]
        coordBoxMajor = true
    } else if cShape.count == 3, cShape[0] == 1, cShape[1] == 4 {
        n = cShape[2]
        coordBoxMajor = false
    } else if cShape.count == 2, cShape[1] == 4 {
        n = cShape[0]
        coordBoxMajor = true
    } else {
        throw NevusDetectionError.invalidOutputShape(coordinates.shape)
    }

    func maxConf(forBox i: Int) -> Double {
        if fShape.count == 1, fShape[0] == n {
            return double1D(confidenceArray, i)
        }
        if fShape.count == 2, fShape[0] == n {
            var best = -Double.infinity
            for j in 0..<fShape[1] {
                best = max(best, double2D(confidenceArray, i, j))
            }
            return best
        }
        if fShape.count == 2, fShape[1] == n {
            var best = -Double.infinity
            for j in 0..<fShape[0] {
                best = max(best, double2D(confidenceArray, j, i))
            }
            return best
        }
        if fShape.count == 3, fShape[0] == 1, fShape[1] == n {
            var best = -Double.infinity
            for j in 0..<fShape[2] {
                best = max(best, doubleAt3(confidenceArray, 0, i, j))
            }
            return best
        }
        if fShape.count == 3, fShape[0] == 1, fShape[2] == n {
            var best = -Double.infinity
            for j in 0..<fShape[1] {
                best = max(best, doubleAt3(confidenceArray, 0, j, i))
            }
            return best
        }
        if fShape.count == 3, fShape[1] == n {
            var best = -Double.infinity
            for j in 0..<fShape[2] {
                best = max(best, doubleAt3(confidenceArray, 0, i, j))
            }
            return best
        }
        return 0
    }

    var out: [ScoredRect] = []
    for i in 0..<n {
        let cxN: Double
        let cyN: Double
        let wN: Double
        let hN: Double
        if coordBoxMajor {
            if cShape.count == 3 {
                cxN = doubleAt3(coordinates, 0, i, 0)
                cyN = doubleAt3(coordinates, 0, i, 1)
                wN = doubleAt3(coordinates, 0, i, 2)
                hN = doubleAt3(coordinates, 0, i, 3)
            } else {
                cxN = double2D(coordinates, i, 0)
                cyN = double2D(coordinates, i, 1)
                wN = double2D(coordinates, i, 2)
                hN = double2D(coordinates, i, 3)
            }
        } else {
            cxN = doubleAt3(coordinates, 0, 0, i)
            cyN = doubleAt3(coordinates, 0, 1, i)
            wN = doubleAt3(coordinates, 0, 2, i)
            hN = doubleAt3(coordinates, 0, 3, i)
        }

        let p = confidence(maxConf(forBox: i))
        guard p >= Double(threshold) else { continue }

        let s = Double(YOLOConfig.inputSize)
        let cx = cxN * s
        let cy = cyN * s
        let bw = wN * s
        let bh = hN * s
        let x1 = cx - bw / 2
        let y1 = cy - bh / 2
        guard bw > 1, bh > 1 else { continue }
        out.append(ScoredRect(rect: CGRect(x: x1, y: y1, width: bw, height: bh), score: p))
    }
    return out
}

private func double1D(_ multi: MLMultiArray, _ i: Int) -> Double {
    Double(truncating: multi[[i] as [NSNumber]])
}

private func double2D(_ multi: MLMultiArray, _ a: Int, _ b: Int = 0) -> Double {
    Double(truncating: multi[[a, b] as [NSNumber]])
}

private func doubleAt3(_ multi: MLMultiArray, _ i0: Int, _ i1: Int, _ i2: Int) -> Double {
    Double(truncating: multi[[i0, i1, i2] as [NSNumber]])
}

// MARK: - Letterbox

private struct LetterboxResult {
    let image: UIImage
    /// Коэффициент масштаба Ultralytics
    let gain: CGFloat
    /// Левый и верхний отступы
    let padLeft: CGFloat
    let padTop: CGFloat

    
    static func make(cgImage: CGImage, target: Int) throws -> LetterboxResult {
        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        let t = CGFloat(target)
        let r = min(t / h, t / w)

        let newW = (w * r).rounded()
        let newH = (h * r).rounded()
        let dw = (t - newW) / 2
        let dh = (t - newH) / 2
        let left = (dw - 0.1).rounded()
        let top = (dh - 0.1).rounded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let size = CGSize(width: target, height: target)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let gray = YOLOConfig.letterboxGray
        let img = renderer.image { ctx in
            UIColor(red: gray, green: gray, blue: gray, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let drawRect = CGRect(x: left, y: top, width: newW, height: newH)
            ctx.cgContext.interpolationQuality = .high
            ctx.cgContext.draw(cgImage, in: drawRect)
        }

        return LetterboxResult(image: img, gain: r, padLeft: left, padTop: top)
    }
}



private struct ScoredRect {
    var rect: CGRect
    var score: Double
}

private enum BoxTensorLayout {
    
    case xywhCenter
    case xyxyCorners
}


private func bestDecodeBoxes(from multi: MLMultiArray, confidenceThreshold: Float) throws -> [ScoredRect] {
    let xywh = try decodeBoxes(from: multi, layout: .xywhCenter, confidenceThreshold: confidenceThreshold)
    let xyxy = try decodeBoxes(from: multi, layout: .xyxyCorners, confidenceThreshold: confidenceThreshold)
    let bestWh = xywh.map(\.score).max() ?? 0
    let bestXy = xyxy.map(\.score).max() ?? 0
    if bestXy > bestWh + 0.01 { return xyxy }
    if bestWh > bestXy + 0.01 { return xywh }
    if xyxy.count != xywh.count { return xyxy.count > xywh.count ? xyxy : xywh }
    return xywh
}

private func decodeBoxes(from multi: MLMultiArray, layout: BoxTensorLayout, confidenceThreshold: Float) throws -> [ScoredRect] {
    let shape = multi.shape
    guard shape.count == 3 else {
        throw NevusDetectionError.invalidOutputShape(shape)
    }

    let d0 = shape[0].intValue
    let d1 = shape[1].intValue
    let d2 = shape[2].intValue
    guard d0 == 1 else {
        throw NevusDetectionError.invalidOutputShape(shape)
    }

    let numAnchors: Int
    let rowMajorChannelsFirst: Bool

    if d1 == 5 {
        numAnchors = d2
        rowMajorChannelsFirst = true
    } else if d2 == 5 {
        numAnchors = d1
        rowMajorChannelsFirst = false
    } else {
        throw NevusDetectionError.invalidOutputShape(shape)
    }

    var results: [ScoredRect] = []
    results.reserveCapacity(min(numAnchors, 4096))

    for i in 0..<numAnchors {
        let v0: Double
        let v1: Double
        let v2: Double
        let v3: Double
        let confRaw: Double

        if rowMajorChannelsFirst {
            v0 = doubleAt(multi, 0, 0, i)
            v1 = doubleAt(multi, 0, 1, i)
            v2 = doubleAt(multi, 0, 2, i)
            v3 = doubleAt(multi, 0, 3, i)
            confRaw = doubleAt(multi, 0, 4, i)
        } else {
            v0 = doubleAt(multi, 0, i, 0)
            v1 = doubleAt(multi, 0, i, 1)
            v2 = doubleAt(multi, 0, i, 2)
            v3 = doubleAt(multi, 0, i, 3)
            confRaw = doubleAt(multi, 0, i, 4)
        }

        let p = confidence(confRaw)
        guard p >= Double(confidenceThreshold) else { continue }

        var x1: Double
        var y1: Double
        var x2: Double
        var y2: Double

        switch layout {
        case .xywhCenter:
            let cx = v0
            let cy = v1
            let bw = v2
            let bh = v3
            x1 = cx - bw / 2
            y1 = cy - bh / 2
            x2 = cx + bw / 2
            y2 = cy + bh / 2
        case .xyxyCorners:
            x1 = v0
            y1 = v1
            x2 = v2
            y2 = v3
        }

        if max(v0, v1, v2, v3) <= 1.5 {
            let s = Double(YOLOConfig.inputSize)
            x1 *= s
            y1 *= s
            x2 *= s
            y2 *= s
        }

        let w = x2 - x1
        let h = y2 - y1
        guard w > 1, h > 1 else { continue }

        let rect = CGRect(x: x1, y: y1, width: w, height: h)
        results.append(ScoredRect(rect: rect, score: p))
    }

    return results
}

private func doubleAt(_ multi: MLMultiArray, _ i0: Int, _ i1: Int, _ i2: Int) -> Double {
    Double(truncating: multi[[i0, i1, i2] as [NSNumber]])
}

private func confidence(_ raw: Double) -> Double {
    // В графе Ultralytics scores уже проходят sigmoid перед concat с боксами.
    if raw >= 0, raw <= 1 { return raw }
    if raw > 1 { return 1 }
    return 1 / (1 + exp(-raw))
}

private func mapBoxToOriginal(_ box: CGRect, gain: CGFloat, padLeft: CGFloat, padTop: CGFloat) -> CGRect {
    CGRect(
        x: (box.minX - padLeft) / gain,
        y: (box.minY - padTop) / gain,
        width: box.width / gain,
        height: box.height / gain
    )
}

// MARK: - NMS

private func intersectionOverUnion(_ a: CGRect, _ b: CGRect) -> CGFloat {
    let inter = a.intersection(b)
    guard !inter.isNull, inter.width > 0, inter.height > 0 else { return 0 }
    let interArea = inter.width * inter.height
    let union = a.width * a.height + b.width * b.height - interArea
    guard union > 0 else { return 0 }
    return interArea / union
}

private func nonMaxSuppression(boxes: [ScoredRect], iouThreshold: CGFloat) -> [ScoredRect] {
    let sorted = boxes.sorted { $0.score > $1.score }
    var kept: [ScoredRect] = []
    var candidates = sorted
    while let first = candidates.first {
        candidates.removeFirst()
        kept.append(first)
        candidates = candidates.filter { intersectionOverUnion(first.rect, $0.rect) < iouThreshold }
    }
    return kept
}

// MARK: - UIImage helpers

private extension UIImage {
    func normalizedUpOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
