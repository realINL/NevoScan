package com.example.pipelinetester

import android.content.Context
import android.graphics.Bitmap
import java.io.File
import java.io.FileNotFoundException

internal fun copyAssetToFilesDir(context: Context, assetName: String): File {
    val file = File(context.filesDir, assetName)
    val assetNames = runCatching { context.assets.list("")?.toList() ?: emptyList() }
        .getOrElse { emptyList() }
    if (!assetNames.contains(assetName)) {
        throw FileNotFoundException(
            "В assets не найден '$assetName'. Доступные: ${assetNames.joinToString(", ")}"
        )
    }
    context.assets.open(assetName).use { input ->
        file.outputStream().use { output -> input.copyTo(output) }
    }
    return file
}

internal fun bitmapToImageNetNchw(bitmap: Bitmap): FloatArray {
    val w = bitmap.width
    val h = bitmap.height
    val pixels = IntArray(w * h)
    bitmap.getPixels(pixels, 0, w, 0, 0, w, h)
    val out = FloatArray(3 * w * h)
    val mean = floatArrayOf(0.485f, 0.456f, 0.406f)
    val std = floatArrayOf(0.229f, 0.224f, 0.225f)
    for (i in pixels.indices) {
        val p = pixels[i]
        val r = ((p ushr 16) and 0xFF) / 255f
        val g = ((p ushr 8) and 0xFF) / 255f
        val b = (p and 0xFF) / 255f
        out[i] = (r - mean[0]) / std[0]
        out[w * h + i] = (g - mean[1]) / std[1]
        out[2 * w * h + i] = (b - mean[2]) / std[2]
    }
    return out
}

internal fun binaryMaskUpscaleNearest(
    src: ByteArray,
    sw: Int,
    sh: Int,
    dw: Int,
    dh: Int
): ByteArray {
    val out = ByteArray(dw * dh)
    if (sw <= 0 || sh <= 0 || dw <= 0 || dh <= 0) return out
    for (yo in 0 until dh) {
        for (xo in 0 until dw) {
            val sy = (((yo + 0.5f) * sh / dh).toInt()).coerceIn(0, sh - 1)
            val sx = (((xo + 0.5f) * sw / dw).toInt()).coerceIn(0, sw - 1)
            out[yo * dw + xo] = src[sy * sw + sx]
        }
    }
    return out
}

internal fun binaryMaskNearestExpandedToNchw(
    src: ByteArray,
    sw: Int,
    sh: Int,
    dw: Int,
    dh: Int,
    channels: Int
): FloatArray {
    val base = FloatArray(dw * dh)
    if (sw > 0 && sh > 0) {
        for (y in 0 until dh) {
            for (x in 0 until dw) {
                val sy = (((y + 0.5f) * sh / dh).toInt()).coerceIn(0, sh - 1)
                val sx = (((x + 0.5f) * sw / dw).toInt()).coerceIn(0, sw - 1)
                base[y * dw + x] = if (src[sy * sw + sx] != 0.toByte()) 1f else 0f
            }
        }
    }
    if (channels <= 1) return base
    val plane = dw * dh
    val out = FloatArray(channels * plane)
    for (c in 0 until channels) {
        val offset = c * plane
        for (i in 0 until plane) {
            out[offset + i] = base[i]
        }
    }
    return out
}
