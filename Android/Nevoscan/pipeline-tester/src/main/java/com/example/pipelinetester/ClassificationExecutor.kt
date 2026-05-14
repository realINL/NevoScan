package com.example.pipelinetester

import android.content.Context
import android.graphics.Bitmap
import android.os.SystemClock
import org.pytorch.executorch.EValue
import org.pytorch.executorch.Module
import org.pytorch.executorch.Tensor

data class ClassificationResult(
    val probBenign: Float,
    val probMalign: Float,
    val predictedMalignant: Boolean,
    val inferenceMs: Long
)

class ClassificationExecutor(
    private val context: Context,
    private val modelPath: String
) {
    private var module: Module? = null

    fun setup() {
        val file = copyAssetToFilesDir(context, modelPath)
        val mod = Module.load(file.absolutePath)
        module = mod
        runCatching { mod.loadMethod("forward") }
    }

    fun clear() {
        module = null
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

        val imgData = pilBilinearResizeToRgb01Nchw(image, size, size)

        val maskSide = Constants.CLASSIFIER_MASK_SIZE
        val maskData = binaryMaskBlockDownsampleTo8x8(
            src = segMask,
            sw = segMaskWidth,
            sh = segMaskHeight,
            dw = maskSide,
            dh = maskSide,
        )

        val imgShape = longArrayOf(1, 3, size.toLong(), size.toLong())
        val maskShape = longArrayOf(1, 1, maskSide.toLong(), maskSide.toLong())
        val imgTensor = Tensor.fromBlob(imgData, imgShape)
        val maskTensor = Tensor.fromBlob(maskData, maskShape)
        val outArr = mod.forward(EValue.from(imgTensor), EValue.from(maskTensor))
        require(outArr.isNotEmpty()) { "ExecuTorch (classifier): пустой output" }

        val (pBenign, pMalign) = extractTwoClassProbs(outArr[0].toTensor().dataAsFloatArray)

        val predMalign = pMalign >= Constants.MALIGNANCY_THRESHOLD
        val ms = SystemClock.uptimeMillis() - start
        return ClassificationResult(
            probBenign = pBenign,
            probMalign = pMalign,
            predictedMalignant = predMalign,
            inferenceMs = ms
        )
    }

    private fun extractTwoClassProbs(probs: FloatArray): Pair<Float, Float> {
        return when (probs.size) {
            2 -> probs[0] to probs[1]
            else -> {
                val n = probs.size
                require(n >= 2) { "Ожидались вероятности 2 классов, получено ${probs.size}" }
                probs[n - 2] to probs[n - 1]
            }
        }
    }
}
