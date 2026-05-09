package com.example.nevoscan

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import kotlin.math.max


fun prepareImageLikeMainPyBeforeSegmentation(bitmap: Bitmap): Bitmap =
    if (bitmap.config == Bitmap.Config.HARDWARE) {
        bitmap.copy(Bitmap.Config.ARGB_8888, false)
    } else {
        bitmap
    }


fun cropBitmapWithNormalizedBox(bitmap: Bitmap, box: BoundingBox): Bitmap {
    val w = bitmap.width
    val h = bitmap.height
    val x1 = (box.x1 * w).toInt().coerceIn(0, (w - 1).coerceAtLeast(0))
    val y1 = (box.y1 * h).toInt().coerceIn(0, (h - 1).coerceAtLeast(0))
    val x2 = (box.x2 * w).toInt().coerceIn(x1 + 1, w)
    val y2 = (box.y2 * h).toInt().coerceIn(y1 + 1, h)
    return Bitmap.createBitmap(bitmap, x1, y1, x2 - x1, y2 - y1)
}


fun drawBoundingBoxOnBitmap(bitmap: Bitmap, box: BoundingBox): Bitmap {
    val copy = bitmap.copy(Bitmap.Config.ARGB_8888, true) ?: bitmap
    val canvas = Canvas(copy)
    val wf = bitmap.width.toFloat()
    val hf = bitmap.height.toFloat()

    val left = (box.x1 * wf).coerceIn(0f, wf)
    val top = (box.y1 * hf).coerceIn(0f, hf)
    val right = (box.x2 * wf).coerceIn(left, wf)
    val bottom = (box.y2 * hf).coerceIn(top, hf)

    val overlay = Path().apply { addRect(0f, 0f, wf, hf, Path.Direction.CW) }
    val hole = Path().apply { addRect(left, top, right, bottom, Path.Direction.CW) }
    overlay.op(hole, Path.Op.DIFFERENCE)

    val dimPaint = Paint().apply {
        color = Color.argb(85, 0, 0, 0)
        style = Paint.Style.FILL
        isAntiAlias = true
    }
    canvas.drawPath(overlay, dimPaint)

    val strokePx = (max(bitmap.width, bitmap.height) * 0.01f).coerceIn(2f, 8f)
    val outlinePaint = Paint().apply {
        color = Color.WHITE
        style = Paint.Style.STROKE
        strokeWidth = strokePx
        isAntiAlias = true
        // Для эффекта скругления используем PathEffect с радиусом 15
        pathEffect = android.graphics.CornerPathEffect(15f)
    }
    canvas.drawRect(left, top, right, bottom, outlinePaint)

    return copy
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
