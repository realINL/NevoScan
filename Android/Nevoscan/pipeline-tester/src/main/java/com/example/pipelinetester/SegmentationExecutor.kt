package com.example.pipelinetester

import android.content.Context
import android.graphics.Bitmap
import android.os.SystemClock
import kotlin.math.exp
import org.pytorch.executorch.EValue
import org.pytorch.executorch.Module
import org.pytorch.executorch.Tensor

data class SegmentationResult(
    val mask: ByteArray,
    val maskWidth: Int,
    val maskHeight: Int,
    val inferenceMs: Long
)

class SegmentationExecutor(
    private val context: Context,
    private val modelPath: String
) {
    private var module: Module? = null

    fun setup() {
        val file = copyAssetToFilesDir(context, modelPath)
        module = Module.load(file.absolutePath)
    }

    fun segment(source: Bitmap): SegmentationResult {
        val loadedModule = module ?: error("Segmentation model is not loaded")
        val start = SystemClock.uptimeMillis()
        val inputSize = Constants.SEGMENTATION_INPUT_SIZE
        val resized = Bitmap.createScaledBitmap(source, inputSize, inputSize, true)
        val input = bitmapToImageNetNchw(resized)
        resized.recycle()

        val tensor = Tensor.fromBlob(input, longArrayOf(1, 3, inputSize.toLong(), inputSize.toLong()))
        val outputs = loadedModule.forward(EValue.from(tensor))
        require(outputs.isNotEmpty()) { "ExecuTorch вернул пустой output" }

        val out = outputs[0].toTensor().dataAsFloatArray
        val binaryMask = thresholdSigmoidMask(out, inputSize, inputSize, Constants.SEGMENTATION_THRESHOLD)
        val inferenceTime = SystemClock.uptimeMillis() - start
        return SegmentationResult(binaryMask, inputSize, inputSize, inferenceTime)
    }

    private fun thresholdSigmoidMask(
        logits: FloatArray,
        width: Int,
        height: Int,
        threshold: Float
    ): ByteArray {
        val total = width * height
        val out = ByteArray(total)
        if (logits.isEmpty()) return out
        val offset = when {
            logits.size >= total * 2 -> logits.size - total
            logits.size >= total -> logits.size - total
            else -> 0
        }
        for (i in 0 until total) {
            val idx = (offset + i).coerceAtMost(logits.lastIndex)
            val p = 1f / (1f + exp(-logits[idx].coerceIn(-50f, 50f)))
            out[i] = if (p > threshold) 1 else 0
        }
        return out
    }
}
