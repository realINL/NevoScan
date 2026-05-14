package com.example.pipelinetester

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import java.io.File
import java.io.FileNotFoundException

internal fun copyAssetToFilesDir(context: Context, assetName: String): File {
    val file = File(context.filesDir, assetName)
    val assetNames = runCatching { context.assets.list("")?.toList() ?: emptyList() }
        .getOrElse { emptyList() }
    if (!assetNames.contains(assetName)) {
        runCatching { if (file.exists()) file.delete() }
        throw FileNotFoundException(
            "В assets не найден '$assetName'. Доступные файлы: ${assetNames.joinToString(", ")}"
        )
    }
    context.assets.open(assetName).use { input ->
        file.outputStream().use { output ->
            input.copyTo(output)
        }
    }
    return file
}

internal fun bitmapPreparedForMl(bitmap: Bitmap): Bitmap {
    val oriented = bitmap.normalizedUpOrientation()
    val rgb = oriented.stripAlphaOnWhite()
    return when (rgb.config) {
        Bitmap.Config.HARDWARE -> rgb.copy(Bitmap.Config.ARGB_8888, false) ?: rgb
        else -> rgb
    }
}

private fun Bitmap.normalizedUpOrientation(): Bitmap = this

private fun Bitmap.stripAlphaOnWhite(): Bitmap {
    if (!hasAlpha()) return this
    val out = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(out)
    canvas.drawColor(Color.WHITE)
    canvas.drawBitmap(this, 0f, 0f, null)
    return out
}

internal fun pilBilinearResizeToRgb01Nchw(
    bitmap: Bitmap,
    dstW: Int,
    dstH: Int,
): FloatArray {
    val prepared = bitmapPreparedForMl(bitmap)
    val recyclePrepared = prepared !== bitmap
    try {
        val sw = prepared.width
        val sh = prepared.height
        if (sw <= 0 || sh <= 0 || dstW <= 0 || dstH <= 0) {
            return FloatArray(3 * dstW * dstH)
        }
        val pixels = IntArray(sw * sh)
        prepared.getPixels(pixels, 0, sw, 0, 0, sw, sh)
        val scaleX = sw.toFloat() / dstW
        val scaleY = sh.toFloat() / dstH
        val plane = dstW * dstH
        val out = FloatArray(3 * plane)
        for (dy in 0 until dstH) {
            for (dx in 0 until dstW) {
                val srcX = (dx + 0.5f) * scaleX - 0.5f
                val srcY = (dy + 0.5f) * scaleY - 0.5f
                val (r, g, b) = sampleBilinearRgb01(pixels, sw, sh, srcX, srcY)
                val i = dy * dstW + dx
                out[i] = r
                out[plane + i] = g
                out[2 * plane + i] = b
            }
        }
        return out
    } finally {
        if (recyclePrepared) prepared.recycle()
    }
}

private fun sampleBilinearRgb01(
    pixels: IntArray,
    sw: Int,
    sh: Int,
    x: Float,
    y: Float,
): Triple<Float, Float, Float> {
    val xClamped = x.coerceIn(0f, (sw - 1).toFloat())
    val yClamped = y.coerceIn(0f, (sh - 1).toFloat())
    val x0 = xClamped.toInt()
    val y0 = yClamped.toInt()
    val x1 = minOf(x0 + 1, sw - 1)
    val y1 = minOf(y0 + 1, sh - 1)
    val fx = xClamped - x0
    val fy = yClamped - y0

    fun ch(p: Int, shift: Int) = ((p shr shift) and 0xFF) / 255f

    val p00 = pixels[y0 * sw + x0]
    val p01 = pixels[y0 * sw + x1]
    val p10 = pixels[y1 * sw + x0]
    val p11 = pixels[y1 * sw + x1]

    fun lerp(a: Float, b: Float, t: Float) = a + (b - a) * t

    val r = lerp(lerp(ch(p00, 16), ch(p01, 16), fx), lerp(ch(p10, 16), ch(p11, 16), fx), fy)
    val g = lerp(lerp(ch(p00, 8), ch(p01, 8), fx), lerp(ch(p10, 8), ch(p11, 8), fx), fy)
    val b = lerp(lerp(ch(p00, 0), ch(p01, 0), fx), lerp(ch(p10, 0), ch(p11, 0), fx), fy)
    return Triple(r, g, b)
}

internal fun binaryMaskBlockDownsampleTo8x8(
    src: ByteArray,
    sw: Int,
    sh: Int,
    dw: Int = 8,
    dh: Int = 8,
): FloatArray {
    val out = FloatArray(dw * dh)
    if (sw <= 0 || sh <= 0) return out
    for (y in 0 until dh) {
        for (x in 0 until dw) {
            val sx = (x * sw / dw).coerceIn(0, sw - 1)
            val sy = (y * sh / dh).coerceIn(0, sh - 1)
            out[y * dw + x] = if (src[sy * sw + sx] != 0.toByte()) 1f else 0f
        }
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
