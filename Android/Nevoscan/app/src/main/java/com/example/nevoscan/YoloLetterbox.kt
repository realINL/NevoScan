package com.example.nevoscan

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import kotlin.math.max
import kotlin.math.roundToInt

data class YoloLetterbox(
    val bitmap: Bitmap,
    val padW: Float,
    val padH: Float,
    val scale: Float,
    val srcW: Int,
    val srcH: Int,
    val dstW: Int,
    val dstH: Int
) {
    fun recycleBitmapIfNotSame(other: Bitmap) {
        if (bitmap != other) bitmap.recycle()
    }
}

fun mapYoloBoxFromLetterboxToSource(
    box: BoundingBox,
    letterbox: YoloLetterbox
): BoundingBox {
    val (tw, th) = letterbox.dstW to letterbox.dstH
    val padW = letterbox.padW
    val padH = letterbox.padH
    val s = letterbox.scale
    val sw = letterbox.srcW
    val sh = letterbox.srcH
    if (s <= 0f) return box

    fun toSrcX(nx1: Float, nx2: Float): Pair<Float, Float> {
        val x1p = nx1 * tw
        val x2p = nx2 * tw
        val x1o = ((x1p - padW) / s).coerceIn(0f, sw.toFloat())
        val x2o = ((x2p - padW) / s).coerceIn(0f, sw.toFloat())
        val a = minOf(x1o, x2o)
        val b = maxOf(x1o, x2o)
        return (a / sw) to (b / sw)
    }
    fun toSrcY(ny1: Float, ny2: Float): Pair<Float, Float> {
        val y1p = ny1 * th
        val y2p = ny2 * th
        val y1o = ((y1p - padH) / s).coerceIn(0f, sh.toFloat())
        val y2o = ((y2p - padH) / s).coerceIn(0f, sh.toFloat())
        val a = minOf(y1o, y2o)
        val b = maxOf(y1o, y2o)
        return (a / sh) to (b / sh)
    }
    val (x1, x2) = toSrcX(box.x1, box.x2)
    val (y1, y2) = toSrcY(box.y1, box.y2)
    val cx = (x1 + x2) / 2f
    val cy = (y1 + y2) / 2f
    val w = (x2 - x1).coerceAtLeast(1e-6f)
    val h = (y2 - y1).coerceAtLeast(1e-6f)
    return box.copy(
        x1 = x1, y1 = y1, x2 = x2, y2 = y2,
        cx = cx, cy = cy, w = w, h = h
    )
}

fun makeYoloLetterboxBitmap(
    source: Bitmap,
    newW: Int,
    newH: Int,
    padRgb: Int = 114
): YoloLetterbox {
    val w = source.width
    val h = source.height
    if (w <= 0 || h <= 0) {
        val out = Bitmap.createBitmap(newW, newH, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        canvas.drawColor(Color.rgb(padRgb, padRgb, padRgb))
        return YoloLetterbox(
            bitmap = out,
            padW = 0f,
            padH = 0f,
            scale = 1f,
            srcW = max(1, w),
            srcH = max(1, h),
            dstW = newW,
            dstH = newH
        )
    }
    val r = minOf(newH.toFloat() / h, newW.toFloat() / w)
    val newUnpaddedW = max(1, (w * r).roundToInt())
    val newUnpaddedH = max(1, (h * r).roundToInt())
    val scaled = if (newUnpaddedW != w || newUnpaddedH != h) {
        Bitmap.createScaledBitmap(source, newUnpaddedW, newUnpaddedH, true)
    } else {
        source
    }
    val out = Bitmap.createBitmap(newW, newH, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(out)
    canvas.drawColor(Color.rgb(padRgb, padRgb, padRgb))
    val left = (newW - newUnpaddedW) / 2f
    val top = (newH - newUnpaddedH) / 2f
    val paint = Paint().apply { isAntiAlias = true; isFilterBitmap = true }
    canvas.drawBitmap(scaled, left, top, paint)
    if (scaled != source) {
        scaled.recycle()
    }
    return YoloLetterbox(
        bitmap = out,
        padW = left,
        padH = top,
        scale = r,
        srcW = w,
        srcH = h,
        dstW = newW,
        dstH = newH
    )
}
