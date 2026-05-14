//
//  SegmenterProtocol.swift
//  NevoScan
//
//  Created by Илья Лебедев on 09.05.2026.
//

import Foundation
import UIKit
import CoreML

protocol SegmenterProtocol {
    func runSegmentation(on image: UIImage) async throws -> (maskResult: UIImage, maskArray: MLMultiArray)
}

protocol DetectorProtocol {
    func detectMole(on image: UIImage) throws -> (crop: UIImage, annotaion: UIImage)
}

protocol ClassifierProtocol {
    func probabilities(image: UIImage, mask: MLMultiArray) throws -> (benign: Double, malign: Double)
    
}

protocol EngineProtocol {

    func detect(on image: UIImage) async throws -> (cropedImage: UIImage,
                                                    detectedImage: UIImage)
    
    func predict(on image: UIImage) async throws -> Research
}
