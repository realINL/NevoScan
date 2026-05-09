package com.example.pipelinetester

import android.content.Context
import android.graphics.Bitmap
import android.os.SystemClock
import kotlin.math.exp
import org.pytorch.executorch.EValue
import org.pytorch.executorch.Module
import org.pytorch.executorch.Tensor

data class ClassificationResult(
    val probBenign: Float,
    val probMalign: Float,
    val inferenceMs: Long
)

class ClassificationExecutor(
    private val context: Context,
    private val modelPath: String
) {
    private var module: Module? = null

    fun setup() {
        val file = copyAssetToFilesDir(context, modelPath)
        module = Module.load(file.absolutePath)
    }

    fun classify(
        image: Bitmap,
        segMask: ByteArray,
        segMaskWidth: Int,
        segMaskHeight: Int
    ): ClassificationResult {
        val mod = module ?: error("Classification model is not loaded")
        val size = Constants.CLASSIFIER_INPUT_SIZE
        val start = SystemClock.uptimeMillis()

        val resized = Bitmap.createScaledBitmap(image, size, size, true)
        val imgData = bitmapToImageNetNchw(resized)
        if (resized != image) resized.recycle()

        val maskSide = Constants.CLASSIFIER_MASK_SIZE
        val maskChannels = Constants.CLASSIFIER_MASK_CHANNELS
        val maskData = binaryMaskNearestExpandedToNchw(
            src = segMask,
            sw = segMaskWidth,
            sh = segMaskHeight,
            dw = maskSide,
            dh = maskSide,
            channels = maskChannels
        )

        val imgTensor = Tensor.fromBlob(imgData, longArrayOf(1, 3, size.toLong(), size.toLong()))
        val maskTensor = Tensor.fromBlob(
            maskData,
            longArrayOf(1, maskChannels.toLong(), maskSide.toLong(), maskSide.toLong())
        )
        val outArr = mod.forward(EValue.from(imgTensor), EValue.from(maskTensor))
        require(outArr.isNotEmpty()) { "ExecuTorch (classifier): пустой output" }

        val logits = outArr[0].toTensor().dataAsFloatArray
        val (logBenign, logMalign) = extractTwoClassLogits(logits)
        val (pBenign, pMalign) = softmax2(logBenign, logMalign)

        val ms = SystemClock.uptimeMillis() - start
        return ClassificationResult(
            probBenign = pBenign,
            probMalign = pMalign,
            inferenceMs = ms
        )
    }

    private fun extractTwoClassLogits(logits: FloatArray): Pair<Float, Float> {
        return when (logits.size) {
            2 -> logits[0] to logits[1]
            else -> {
                val n = logits.size
                require(n >= 2) { "Ожидались логиты 2 классов, получено ${logits.size}" }
                logits[n - 2] to logits[n - 1]
            }
        }
    }

    private fun softmax2(a: Float, b: Float): Pair<Float, Float> {
        val m = maxOf(a, b)
        val ea = exp((a - m).coerceIn(-50f, 50f))
        val eb = exp((b - m).coerceIn(-50f, 50f))
        val s = ea + eb
        return (ea / s) to (eb / s)
    }
}
