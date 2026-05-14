package com.example.pipelinetester

import android.content.Context
import android.graphics.Bitmap
import android.os.SystemClock
import org.pytorch.executorch.EValue
import org.pytorch.executorch.Module
import org.pytorch.executorch.Tensor

class SegmentationExecutor(
    private val context: Context,
    private val modelPath: String
) {
    private var module: Module? = null

    fun setup() {
        val file = copyAssetToFilesDir(context, modelPath)
        module = Module.load(file.absolutePath)
    }

    fun clear() {
        module = null
    }

    fun segment(source: Bitmap): SegmentationResult {
        val loadedModule = module ?: error("Segmentation model is not loaded")
        val start = SystemClock.uptimeMillis()
        val inputSize = Constants.SEGMENTATION_INPUT_SIZE
        val input = pilBilinearResizeToRgb01Nchw(source, inputSize, inputSize)

        val inputTensor = Tensor.fromBlob(
            input,
            longArrayOf(1, 3, inputSize.toLong(), inputSize.toLong())
        )
        val outputs = loadedModule.forward(EValue.from(inputTensor))
        require(outputs.isNotEmpty()) { "ExecuTorch вернул пустой output" }

        val probs = outputs[0].toTensor().dataAsFloatArray
        val binaryMask = thresholdProbMask(probs, inputSize, inputSize, Constants.SEGMENTATION_THRESHOLD)
        val inferenceTime = SystemClock.uptimeMillis() - start
        return SegmentationResult(binaryMask, inputSize, inputSize, inferenceTime)
    }

    companion object {
        private fun thresholdProbMask(
            probs: FloatArray,
            width: Int,
            height: Int,
            threshold: Float
        ): ByteArray {
            val total = width * height
            val out = ByteArray(total)
            if (probs.isEmpty()) return out

            val offset = when {
                probs.size >= total * 2 -> probs.size - total
                probs.size >= total -> probs.size - total
                else -> 0
            }

            for (i in 0 until total) {
                val idx = (offset + i).coerceAtMost(probs.lastIndex)
                out[i] = if (probs[idx] > threshold) 1 else 0
            }
            return out
        }
    }
}

data class SegmentationResult(
    val mask: ByteArray,
    val maskWidth: Int,
    val maskHeight: Int,
    val inferenceMs: Long
)
