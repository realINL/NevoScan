package com.example.pipelinetester

import android.graphics.Bitmap

fun prepareImageLikeMainPyBeforeSegmentation(bitmap: Bitmap): Bitmap =
    if (bitmap.config == Bitmap.Config.HARDWARE) {
        bitmap.copy(Bitmap.Config.ARGB_8888, false)
    } else {
        bitmap
    }

fun renderBinaryMaskGrayscale(mask01: ByteArray, width: Int, height: Int): Bitmap {
    require(mask01.size >= width * height) { "mask size ${mask01.size} < ${width * height}" }
    val out = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    val pixels = IntArray(width * height)
    var i = 0
    while (i < width * height) {
        val v = if (mask01[i].toInt() and 0xFF != 0) 0xFF else 0x00
        pixels[i] = (0xFF shl 24) or (v shl 16) or (v shl 8) or v
        i++
    }
    out.setPixels(pixels, 0, width, 0, 0, width, height)
    return out
}
