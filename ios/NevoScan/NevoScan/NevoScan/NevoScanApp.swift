//
//  NevoScanApp.swift
//  NevoScan
//
//  Created by Илья Лебедев on 16.01.2026.
//

import SwiftUI
import SwiftData
import UIKit
import YOLO
import PhotosUI
import CoreML
import Vision

@main
struct NevoScanApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Research.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            UserDefaults.standard.set(true, forKey: "nv_debug_pipeline_dump")
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    
    var body: some Scene {
        WindowGroup {
            ContentView()
//                .environment(\.container, DIContainer)
            
        }
        .modelContainer(sharedModelContainer)
        
    }
//    func t() {
//        guard let image = selectedImage else { return }
//        Task {
//            do {
//                try await eng.detectMole(on: image) { crop, draw in
//                    croppedImage = crop
//                    detectorAnnotatedImage = draw
//                }
//            } catch {
//                print(error.localizedDescription)
//            }
//            
//        }
//    }
//    func g() {
//        segmentationOverlayImage = nil
//        mask = nil
//        //                let photo = UIImage(resource: .dd)
//        //                let detector = Detector()
//        //                try? detector.makePredictions(for: photo) { _, annotated in
//        //                    DispatchQueue.main.async {
//        //                        detectorAnnotatedImage = annotated ?? photo
//        //                    }
//        //                }
//        //                do {
//                        guard let imageUrl = Bundle.main.url(forResource: "ddd", withExtension: "jpg") else { print("No image"); return }
//        guard let output = try? best(configuration: .init()).prediction(input: bestInput(imageAt: imageUrl)) else { print("XZ SUKA"); return }
//        print(output.featureNames)
////        print(output.confidence)
////        print(output.coordinates)
////                        print(output.var_910)
//        //                print(output.var_910.count)
//        //                } catch {
//        //
//        //                }
//        // 1
//        lazy var classificationRequest: VNCoreMLRequest = {
//            do {
//                // 2
//                let config = MLModelConfiguration()
//                
//                let model = try VNCoreMLModel(for: best(configuration: config).model)
//                // 3
//                let request = VNCoreMLRequest(model: model) { request, _ in
//                    if let classifications =
//                        request.results as? [VNDetectRectanglesRequest] {
//                        print("Результат классификации 1: \(classifications)")
//                    } else if let classifications =
//                                request.results as? [VNRecognizedObjectObservation]  {
//                        print("Результат классификации 2: \(classifications)")
//                        detectorAnnotatedImage = drawBoundingBox(on: selectedImage!, observation: classifications[0])
//                    } else if let classifications =
//                                request.results as? [VNCoreMLFeatureValueObservation]  {
//                        print("Результат классификации 3: \(classifications)")
////                        detectorAnnotatedImage = drawBoundingBox(on: selectedImage!, observation: classifications[0])
//                    } else {
//                        print("XZ SUKA")
//                    }
//                }
//                // 4
//                request.imageCropAndScaleOption = .centerCrop
//                return request
//            } catch {
//                // 5
//                fatalError("Failed to load Vision ML model: \(error)")
//            }
//        }()
//        if let img = selectedImage {
//            classifyImage(img, request: classificationRequest)
//        }
//        
////        let img = getCorrectOrientationUIImage(uiImage: selectedImage!)
////                        yoloResult = yolo(img)
////                        print(yoloResult?.boxes.count)
////       new detecotr
//        try? eng.detectMole(on: selectedImage!) {crop, annotaion in
//            croppedImage = crop
//            detectorAnnotatedImage = annotaion
//        }
//        if let image = croppedImage {
////        if let image = selectedImage, let result = yoloResult {
////            croppedImage = cropImage(image: image, result: result)
//            var s: Segmenter? = nil
//            do {
//                s = try Segmenter()
//            } catch {
//                print(error.localizedDescription)
//            }
//            
//            guard let seg = s else { return }
//            guard let classifier = try? ResNetFeatMaskClassifier.loadBundled() else { return }
//            let crop = image
////            seg.runSegmentation(on: crop) { maskResult, maskArray in
////                mask = maskResult
////                print("set mask")
////                if let maskRes = maskResult, let arr = maskArray {
////                    classificationResult = try? classifier.probabilities(from: maskRes, mask256: arr)
////                }
////                Task { @MainActor in
////                    mask = maskResult
////                    if let m = maskResult {
////                        segmentationOverlayImage = UIImage.nv_segmentationOverlay(base: crop, mask: m, maskAlpha: 0.58)
////                    } else {
////                        segmentationOverlayImage = nil
////                    }
////                }
////            }
//                    
//            
//        }
//        
//    }
//    func classifyImage(_ image: UIImage, request: VNCoreMLRequest) {
//        // 1
//        guard let orientation = CGImagePropertyOrientation(
//            rawValue: UInt32(image.imageOrientation.rawValue)) else {
//            return
//        }
//        guard let ciImage = CIImage(image: image) else {
//            fatalError("Unable to create \(CIImage.self) from \(image).")
//        }
//        // 2
//        DispatchQueue.global(qos: .userInitiated).async {
//            let handler =
//            VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
//            do {
//                try handler.perform([request])
//            } catch {
//                print("Failed to perform classification.\n\(error.localizedDescription)")
//            }
//        }
//    }
//    func drawBoundingBox(on image: UIImage, observation: VNRecognizedObjectObservation) -> UIImage? {
//        let imageSize = image.size
//        let boundingBox = observation.boundingBox
//        
//        // Конвертация нормализованных координат в пиксельные
//        // Т.к. у Vision Y=0 снизу, а UIKit Y=0 сверху — делаем преобразование
//        let rect = CGRect(
//            x: boundingBox.origin.x * imageSize.width,
//            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
//            width: boundingBox.width * imageSize.width,
//            height: boundingBox.height * imageSize.height
//        )
//        
//        // Начинаем рисовать
//        UIGraphicsBeginImageContextWithOptions(imageSize, false, image.scale)
//        defer { UIGraphicsEndImageContext() }
//        
//        image.draw(at: .zero)
//        
//        let context = UIGraphicsGetCurrentContext()
//        context?.setStrokeColor(UIColor.red.cgColor)
//        context?.setLineWidth(4)
//        context?.stroke(rect)
//        
//        //  текст с confidence
//        let text = String(format: "%.2f", observation.confidence)
//        let attributes: [NSAttributedString.Key: Any] = [
//            .font: UIFont.boldSystemFont(ofSize: 16),
//            .foregroundColor: UIColor.red
//        ]
//        text.draw(at: CGPoint(x: rect.origin.x, y: rect.origin.y - 20), withAttributes: attributes)
//        
//        return UIGraphicsGetImageFromCurrentImageContext()
//    }
//    func cropImage(image: UIImage, result: YOLOResult) -> UIImage? {
//        let cgImage = image.cgImage
//        let firstbox = result.boxes[0]
//        let rect = firstbox.xywh
//        
//        if let croppedImage = cgImage?.cropping(to: rect) {
//            return UIImage(cgImage: croppedImage)
//        } else {
//            return nil
//        }
//    }
//    
//    func getCorrectOrientationUIImage(uiImage: UIImage) -> UIImage {
//        var newImage = UIImage()
//        let ciContext = CIContext()
//        switch uiImage.imageOrientation.rawValue {
//        case 1:
//            guard let orientedCIImage = CIImage(image: uiImage)?.oriented(CGImagePropertyOrientation.down),
//                  let cgImage = ciContext.createCGImage(orientedCIImage, from: orientedCIImage.extent)
//            else { return uiImage }
//            
//            newImage = UIImage(cgImage: cgImage)
//        case 3:
//            guard let orientedCIImage = CIImage(image: uiImage)?.oriented(CGImagePropertyOrientation.right),
//                  let cgImage = ciContext.createCGImage(orientedCIImage, from: orientedCIImage.extent)
//            else { return uiImage }
//            newImage = UIImage(cgImage: cgImage)
//        default:
//            newImage = uiImage
//        }
//        return newImage
//    }
}

// MARK: - Наложение маски сегментации на кроп

private extension UIImage {
    static func nv_segmentationOverlay(
        base: UIImage,
        mask: UIImage,
        maskAlpha: CGFloat = 0.58
    ) -> UIImage {
        let size = base.size
        let scale = base.scale
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            base.draw(in: rect)
            let scaledMask = mask.nv_scaledToMatchBaseSize(baseSize: size, baseScale: scale)
            scaledMask.draw(in: rect, blendMode: .normal, alpha: maskAlpha)
        }
    }

    func nv_scaledToMatchBaseSize(baseSize: CGSize, baseScale: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = baseScale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: baseSize, format: format)
        return renderer.image { ctx in
            ctx.cgContext.interpolationQuality = .high
            self.draw(in: CGRect(origin: .zero, size: baseSize))
        }
    }
}
