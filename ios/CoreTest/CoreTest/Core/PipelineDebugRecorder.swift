//
//  PipelineDebugRecorder.swift
//  CoreTest
//
//  Временные снимки для JSON-дампа сравнения с Python (`debug_compare_pipeline.py`).
//  Логика пайплайна не меняется — только запись под флагом DEBUG + UserDefaults.
//

import CoreML
import Foundation

#if DEBUG
enum PipelineDebugRecorder {
    private static var segInputSample3x4x4: [[[Float]]]?
    /// True — тензор как в `exportmodels.ipynb` (0…1 float NCHW); false — старый DeepLab (0…255 float).
    private static var segInputIsFloat01: Bool?
    private static var inputImagePixelWidth: Int?
    private static var inputImagePixelHeight: Int?

    static func reset() {
        segInputSample3x4x4 = nil
        segInputIsFloat01 = nil
        inputImagePixelWidth = nil
        inputImagePixelHeight = nil
    }

    /// Вызывается из сегментатора сразу после сборки тензора входа сегментации (реальный масштаб — см. `isFloat01`).
    static func recordSegInputIfNeeded(
        segInput: MLMultiArray,
        isFloat01: Bool,
        preparedCGImageWidth: Int,
        preparedCGImageHeight: Int
    ) {
        guard UserDefaults.standard.bool(forKey: "nv_debug_pipeline_dump") else { return }
        segInputSample3x4x4 = sampleSegInputNCHW255_3x4x4(segInput)
        segInputIsFloat01 = isFloat01
        inputImagePixelWidth = preparedCGImageWidth
        inputImagePixelHeight = preparedCGImageHeight
    }

    static func snapshotForPipelineDump() -> (
        segInputSample: [[[Float]]]?,
        inputPixelWH: [Int]?,
        segInputIsFloat01: Bool?
    ) {
        let wh: [Int]?
        if let w = inputImagePixelWidth, let h = inputImagePixelHeight {
            wh = [w, h]
        } else {
            wh = nil
        }
        return (segInputSample3x4x4, wh, segInputIsFloat01)
    }

    private static func sampleSegInputNCHW255_3x4x4(_ tensor: MLMultiArray) -> [[[Float]]]? {
        let s = tensor.shape.map { $0.intValue }
        guard s.count == 4, s[0] == 1, s[1] >= 3, s[2] >= 4, s[3] >= 4 else { return nil }
        var out = Array(repeating: Array(repeating: Array(repeating: Float(0), count: 4), count: 4), count: 3)
        for c in 0..<3 {
            for y in 0..<4 {
                for x in 0..<4 {
                    out[c][y][x] = Float(truncating: tensor[[0, c, y, x] as [NSNumber]])
                }
            }
        }
        return out
    }
}
#endif
