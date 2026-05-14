import CoreML
import CoreGraphics
import UIKit

/// PIL-совместимый bilinear resize → NCHW float32 MLMultiArray.
///
/// Точно реализует `PIL.Image.resize((dstW, dstH), Image.Resampling.BILINEAR)` + `ToTensor`.
///
/// Ключевое отличие от CG `.medium`: PIL использует half-pixel convention:
///   src_pos = (dst_pos + 0.5) × scale − 0.5
/// CG усредняет блок (area average) без этого сдвига.
/// На практике разница особенно заметна в углах изображения и при большом масштабе (> 4×).
///
/// - Parameters:
///   - srcCg:     Источник. CG конвертирует color space источника → sRGB при рендере.
///   - dstWidth:  Ширина выходного тензора (обычно 256).
///   - dstHeight: Высота выходного тензора (обычно 256).
///   - normalize: Применить ImageNet normalization: `(x/255 − mean) / std`.
///   - mean:      ImageNet mean per channel [R, G, B]. Не используется если `normalize = false`.
///   - std:       ImageNet std per channel [R, G, B].  Не используется если `normalize = false`.
/// - Returns: MLMultiArray shape [1, 3, dstHeight, dstWidth], dtype Float32.
func pilBilinearNCHWTensor(
    from srcCg: CGImage,
    dstWidth: Int,
    dstHeight: Int,
    normalize: Bool,
    mean: [Float],
    std: [Float]
) throws -> MLMultiArray {
    let srcW = srcCg.width
    let srcH = srcCg.height
    guard srcW > 0, srcH > 0, dstWidth > 0, dstHeight > 0 else {
        throw PilBilinearError.badDimensions
    }

    // ── 1. Декодируем источник в sRGB RGBX (без premult-альфы) с top-left origin ──
    guard let sRGB = CGColorSpace(name: CGColorSpace.sRGB) else {
        throw PilBilinearError.colorSpaceUnavailable
    }
    let srcBPP = 4
    let srcBPR = srcBPP * srcW
    var srcPixels = [UInt8](repeating: 255, count: srcH * srcBPR)
    guard let srcCtx = CGContext(
        data: &srcPixels,
        width: srcW, height: srcH,
        bitsPerComponent: 8, bytesPerRow: srcBPR,
        space: sRGB,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue   // RGBX, offset 0=R 1=G 2=B 3=X
    ) else {
        throw PilBilinearError.contextCreationFailed
    }
    // CG-контекст с origin bottom-left. Переворачиваем Y так, чтобы строка 0 буфера = верх кадра
    // (соответствует PIL/NumPy top-left origin).
    srcCtx.translateBy(x: 0, y: CGFloat(srcH))
    srcCtx.scaleBy(x: 1, y: -1)
    // CG автоматически конвертирует цветовое пространство источника → sRGB.
    srcCtx.interpolationQuality = .none   // 1:1 копия в источник; resize сделаем сами
    srcCtx.draw(srcCg, in: CGRect(x: 0, y: 0, width: srcW, height: srcH))

    // ── 2. PIL bilinear → NCHW MLMultiArray ──
    let out = try MLMultiArray(
        shape: [1, 3, NSNumber(value: dstHeight), NSNumber(value: dstWidth)],
        dataType: .float32
    )
    // Быстрый доступ через raw pointer (избегаем NSNumber на каждый пиксель)
    let outPtr = out.dataPointer.bindMemory(to: Float.self, capacity: dstHeight * dstWidth * 3)
    let chStride = dstHeight * dstWidth   // [1, C, H, W] → channel stride = H*W
    let rowStride = dstWidth

    let scaleX = Float(srcW) / Float(dstWidth)
    let scaleY = Float(srcH) / Float(dstHeight)
    let inv255: Float = 1.0 / 255.0

    for dy in 0..<dstHeight {
        // PIL half-pixel convention: src_y = (dy + 0.5) * scaleY - 0.5
        let srcYf = (Float(dy) + 0.5) * scaleY - 0.5
        // floor для srcYf >= 0 совпадает с Int(); clamp к [0, srcH-1]
        let y0 = max(0, min(srcH - 1, Int(srcYf)))
        let y1 = min(y0 + 1, srcH - 1)
        let wy1 = max(0, min(1, srcYf - Float(y0)))
        let wy0 = 1.0 - wy1

        for dx in 0..<dstWidth {
            let srcXf = (Float(dx) + 0.5) * scaleX - 0.5
            let x0 = max(0, min(srcW - 1, Int(srcXf)))
            let x1 = min(x0 + 1, srcW - 1)
            let wx1 = max(0, min(1, srcXf - Float(x0)))
            let wx0 = 1.0 - wx1

            let o00 = y0 * srcBPR + x0 * srcBPP
            let o10 = y0 * srcBPR + x1 * srcBPP
            let o01 = y1 * srcBPR + x0 * srcBPP
            let o11 = y1 * srcBPR + x1 * srcBPP

            let baseIdx = dy * rowStride + dx
            for c in 0..<3 {
                let v = wy0 * (wx0 * Float(srcPixels[o00 + c]) + wx1 * Float(srcPixels[o10 + c]))
                      + wy1 * (wx0 * Float(srcPixels[o01 + c]) + wx1 * Float(srcPixels[o11 + c]))
                var pixF = v * inv255
                if normalize {
                    pixF = (pixF - mean[c]) / std[c]
                }
                outPtr[c * chStride + baseIdx] = pixF
            }
        }
    }
    return out
}

private enum PilBilinearError: Error {
    case badDimensions
    case colorSpaceUnavailable
    case contextCreationFailed
}
