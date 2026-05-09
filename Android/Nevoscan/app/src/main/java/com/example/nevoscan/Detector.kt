package com.example.nevoscan

import android.content.Context
import android.graphics.Bitmap
import android.os.SystemClock
import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OnnxTensorLike
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import ai.onnxruntime.TensorInfo
import java.io.BufferedReader
import java.io.InputStreamReader
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer
import java.io.IOException
import java.io.FileNotFoundException
import java.util.concurrent.CountDownLatch
import kotlin.math.exp

private fun resolveModelAssetName(context: Context, preferred: String): String {
    val names = runCatching { context.assets.list("")?.toList() ?: emptyList() }
        .getOrElse { emptyList() }
    if (names.contains(preferred)) return preferred
    val onnx = names.filter { it.endsWith(".onnx", ignoreCase = true) }
    when {
        onnx.isEmpty() -> throw FileNotFoundException(
            "В assets нет .onnx (ожидалось: $preferred). Файлы: ${names.joinToString(", ")}"
        )
        onnx.size == 1 -> return onnx.first()
        else -> {
            val exact = onnx.find { it.equals(preferred, ignoreCase = true) }
            if (exact != null) return exact
            return onnx.sorted().first()
        }
    }
}

class Detector(
    private val context: Context,
    private val modelPath: String,
    private val labelPath: String,
    private val detectorListener: DetectorListener
) {

    private var ortEnv: OrtEnvironment? = null
    private var session: OrtSession? = null
    private var inputName: String? = null
    private var nchwInput: Boolean = true
    private var labels = mutableListOf<String>()

    private var tensorWidth: Int = 0
    private var tensorHeight: Int = 0
    private var numChannel: Int = 0
    private var numElements: Int = 0
    private var outputCellMajor: Boolean = false
    private var inputShapeHint: LongArray? = null

    private var oneShotListener: DetectorListener? = null


    fun setup(): Boolean {
        labels.clear()
        runCatching { session?.close() }
        session = null
        ortEnv = null
        inputName = null
        return try {
            val assetName = resolveModelAssetName(context, modelPath)
            val modelBytes = context.assets.open(assetName).readBytes()
            val env = OrtEnvironment.getEnvironment()
            ortEnv = env
            val options = OrtSession.SessionOptions()
            runCatching { options.setIntraOpNumThreads(4) }
            val sess = env.createSession(modelBytes, options)
            session = sess
            val inNames = sess.inputNames
            require(inNames.isNotEmpty()) { "ONNX: нет входа" }
            inputName = inNames.first()
            val name = inputName!!
            val nodeInfo = sess.inputInfo[name]
            val info = nodeInfo?.info as? TensorInfo
            val shape = info?.shape ?: longArrayOf(1, 3, 640, 640)
            inputShapeHint = shape
            parseInputShape(shape)

            val labelCandidates = listOf(labelPath, "lables.txt")
            var loaded = false
            for (path in labelCandidates) {
                if (loaded) break
                try {
                    context.assets.open(path).use { inputStream ->
                        BufferedReader(InputStreamReader(inputStream)).use { reader ->
                            var line: String? = reader.readLine()
                            while (line != null && line.isNotEmpty()) {
                                labels.add(line)
                                line = reader.readLine()
                            }
                        }
                    }
                    loaded = true
                } catch (_: IOException) { }
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            runCatching { session?.close() }
            session = null
            ortEnv = null
            inputName = null
            false
        }
    }

    private fun parseInputShape(shape: LongArray) {
        nchwInput = when {
            shape.size >= 4 && shape[1] == 3L -> true
            shape.size >= 4 && shape[3] == 3L -> false
            else -> true
        }
        if (nchwInput && shape.size >= 4) {
            val h = shape[2]
            val w = shape[3]
            tensorHeight = if (h > 0) h.toInt() else 640
            tensorWidth = if (w > 0) w.toInt() else 640
        } else if (!nchwInput && shape.size >= 4) {
            val h = shape[1]
            val w = shape[2]
            tensorHeight = if (h > 0) h.toInt() else 640
            tensorWidth = if (w > 0) w.toInt() else 640
        } else {
            tensorHeight = 640
            tensorWidth = 640
        }
    }

    fun clear() {
        runCatching { session?.close() }
        session = null
    }

    fun detect(frame: Bitmap) {
        val listener = oneShotListener ?: detectorListener
        oneShotListener = null
        val env = ortEnv ?: run {
            listener.onEmptyDetect()
            return
        }
        val sess = session ?: run {
            listener.onEmptyDetect()
            return
        }
        val inName = inputName ?: run {
            listener.onEmptyDetect()
            return
        }
        if (tensorWidth <= 0 || tensorHeight <= 0) {
            listener.onEmptyDetect()
            return
        }

        val inferenceTimeStart = SystemClock.uptimeMillis()
        val letterbox = makeYoloLetterboxBitmap(
            frame,
            tensorWidth,
            tensorHeight,
            padRgb = Constants.YOLO_LETTERBOX_PAD
        )
        val lb = letterbox.bitmap
        val intShape = buildInputShape()
        val inputData = if (nchwInput) {
            bitmapToNchw(lb, tensorWidth, tensorHeight)
        } else {
            bitmapToNhwc(lb, tensorWidth, tensorHeight)
        }
        lb.recycle()

        var inputTensor: OnnxTensor? = null
        var result: OrtSession.Result? = null
        try {
            val buf = floatBufferFor(inputData)
            inputTensor = OnnxTensor.createTensor(env, buf, intShape)
            val inputs: MutableMap<String, OnnxTensorLike> = HashMap(1)
            inputs[inName] = inputTensor
            result = sess.run(inputs)
            val outVal = result.get(0) as? OnnxTensor ?: run {
                listener.onEmptyDetect()
                return
            }
            val outInfo = outVal.info as? TensorInfo ?: run {
                listener.onEmptyDetect()
                return
            }
            val outShape = outInfo.shape
            parseOutputShape(outShape)

            val outSize = outSizeFromShape(outShape)
            if (outSize <= 0) {
                listener.onEmptyDetect()
                return
            }
            val outputArray = FloatArray(outSize)
            outVal.floatBuffer.rewind()
            outVal.floatBuffer.get(outputArray)

            val bestBoxes = bestBox(outputArray)
            val inferenceTime = SystemClock.uptimeMillis() - inferenceTimeStart
            if (bestBoxes == null) {
                listener.onEmptyDetect()
            } else {
                val inSource = bestBoxes.map { mapYoloBoxFromLetterboxToSource(it, letterbox) }
                listener.onDetect(inSource, inferenceTime)
            }
        } catch (e: Exception) {
            e.printStackTrace()
            listener.onEmptyDetect()
        } finally {
            runCatching { inputTensor?.close() }
            runCatching { result?.close() }
        }
    }


    fun detectSync(frame: Bitmap): List<BoundingBox>? {
        val latch = CountDownLatch(1)
        val holder = arrayOfNulls<List<BoundingBox>>(1)
        oneShotListener = object : DetectorListener {
            override fun onEmptyDetect() {
                holder[0] = null
                latch.countDown()
            }

            override fun onDetect(boundingBoxes: List<BoundingBox>, inferenceTime: Long) {
                holder[0] = boundingBoxes
                latch.countDown()
            }
        }
        detect(frame)
        latch.await()
        return holder[0]
    }

    private fun buildInputShape(): LongArray {
        val hint = inputShapeHint
        return if (nchwInput) {
            longArrayOf(
                1,
                3L,
                tensorHeight.toLong(),
                tensorWidth.toLong()
            )
        } else {
            longArrayOf(
                1,
                tensorHeight.toLong(),
                tensorWidth.toLong(),
                3L
            )
        }
    }

    private fun outSizeFromShape(shape: LongArray): Int {
        var s = 1L
        for (d in shape) {
            if (d > 0) s *= d
        }
        return s.coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
    }

    private fun parseOutputShape(outShape: LongArray) {
        var s = outShape
        if (s.size == 4 && s[0] == 1L) {
            s = when {
                s[1] == 1L && s[2] > 0 && s[3] > 0 -> longArrayOf(1, s[2], s[3]) // [1,1,84,8400]
                s[3] == 1L && s[1] > 0 && s[2] > 0 -> longArrayOf(1, s[1], s[2]) // [1,84,8400,1]
                else -> s
            }
        }
        if (s.size == 3) {
            val a = s[1].toInt()
            val b = s[2].toInt()
            if (a < b) {
                numChannel = a
                numElements = b
                outputCellMajor = false
            } else {
                numChannel = b
                numElements = a
                outputCellMajor = true
            }
            return
        }
        numChannel = 0
        numElements = 0
    }

    private fun floatBufferFor(data: FloatArray): FloatBuffer {
        val byteBuffer = ByteBuffer.allocateDirect(data.size * 4).order(ByteOrder.nativeOrder())
        val fb = byteBuffer.asFloatBuffer()
        fb.put(data)
        fb.rewind()
        return fb
    }

    private fun bitmapToNchw(bitmap: Bitmap, w: Int, h: Int): FloatArray {
        val out = FloatArray(3 * h * w)
        val pixels = IntArray(w * h)
        bitmap.getPixels(pixels, 0, w, 0, 0, w, h)
        for (c in 0 until 3) {
            for (i in 0 until w * h) {
                val p = pixels[i]
                val v = when (c) {
                    0 -> ((p ushr 16) and 0xFF) / 255f
                    1 -> ((p ushr 8) and 0xFF) / 255f
                    else -> (p and 0xFF) / 255f
                }
                out[c * w * h + i] = v
            }
        }
        return out
    }

    private fun bitmapToNhwc(bitmap: Bitmap, w: Int, h: Int): FloatArray {
        val out = FloatArray(h * w * 3)
        val pixels = IntArray(w * h)
        bitmap.getPixels(pixels, 0, w, 0, 0, w, h)
        for (i in 0 until w * h) {
            val p = pixels[i]
            val b = 3 * i
            out[b] = ((p ushr 16) and 0xFF) / 255f
            out[b + 1] = ((p ushr 8) and 0xFF) / 255f
            out[b + 2] = (p and 0xFF) / 255f
        }
        return out
    }

    private fun bestBox(array: FloatArray): List<BoundingBox>? {
        if (numChannel == 0 || numElements == 0) return null
        val classCount = numChannel - 4
        if (classCount <= 0) return null
        val invModel = 1f / maxOf(tensorWidth, tensorHeight).toFloat()
        val boundingBoxes = mutableListOf<BoundingBox>()
        for (c in 0 until numElements) {
            var maxConf = -1.0f
            var maxIdx = -1
            var j = 4
            while (j < numChannel) {
                val arrayIdx = if (outputCellMajor) {
                    c * numChannel + j
                } else {
                    c + numElements * j
                }
                if (arrayIdx !in array.indices) {
                    j++
                    continue
                }
                val raw = array[arrayIdx]
                val p = toClassProbability(raw)
                if (p > maxConf) {
                    maxConf = p
                    maxIdx = j - 4
                }
                j++
            }
            if (maxIdx < 0) continue
            if (labels.isNotEmpty() && maxIdx >= labels.size) continue
            if (maxConf <= Constants.INFERENCE_CONF) continue
            val clsName = if (maxIdx in labels.indices) labels[maxIdx] else "cls$maxIdx"
            val i0 = if (outputCellMajor) c * numChannel + 0 else c + numElements * 0
            val i1 = if (outputCellMajor) c * numChannel + 1 else c + numElements * 1
            val i2 = if (outputCellMajor) c * numChannel + 2 else c + numElements * 2
            val i3 = if (outputCellMajor) c * numChannel + 3 else c + numElements * 3
            if (i0 !in array.indices || i1 !in array.indices || i2 !in array.indices || i3 !in array.indices) {
                continue
            }
            var cx = array[i0]
            var cy = array[i1]
            var bw = array[i2]
            var bh = array[i3]
            if (maxOf(cx, cy, bw, bh) > 1.0f) {
                cx *= invModel
                cy *= invModel
                bw *= invModel
                bh *= invModel
            }
            var x1 = cx - (bw / 2F)
            var y1 = cy - (bh / 2F)
            var x2 = cx + (bw / 2F)
            var y2 = cy + (bh / 2F)
            x1 = x1.coerceIn(0f, 1f)
            y1 = y1.coerceIn(0f, 1f)
            x2 = x2.coerceIn(0f, 1f)
            y2 = y2.coerceIn(0f, 1f)
            if (x2 - x1 < 1e-4f || y2 - y1 < 1e-4f) continue
            boundingBoxes.add(
                BoundingBox(
                    x1 = x1, y1 = y1, x2 = x2, y2 = y2,
                    cx = cx, cy = cy, w = bw, h = bh,
                    cnf = maxConf, cls = maxIdx, clsName = clsName
                )
            )
        }
        if (boundingBoxes.isEmpty()) return null
        val sorted = boundingBoxes.sortedByDescending { it.cnf }
        val preNms = sorted.take(effectivePreNmsCap())
        val nms = applyNMS(
            preNms,
            Constants.INFERENCE_IOU_NMS,
            Constants.YOLO_AGNOSTIC_NMS
        )
        return nms.take(effectivePostNmsMax()).toMutableList()
    }

    private fun effectivePostNmsMax(): Int =
        if (numChannel <= 6) postNmsMaxSingleClass() else postNmsMax()

    private fun effectivePreNmsCap(): Int =
        if (numChannel <= 6) PRE_NMS_MAX_SINGLE else PRE_NMS_MAX_MULTI

    private fun toClassProbability(raw: Float): Float {
        return 1f / (1f + exp((-raw).coerceIn(-50f, 50f)))
    }

    private fun applyNMS(
        boxes: List<BoundingBox>,
        iouMerge: Float,
        classAgnostic: Boolean
    ): MutableList<BoundingBox> {
        val sorted = boxes.sortedByDescending { it.cnf }
        if (classAgnostic) {
            val remaining = sorted.toMutableList()
            val selected = mutableListOf<BoundingBox>()
            while (remaining.isNotEmpty()) {
                val first = remaining.removeAt(0)
                selected.add(first)
                remaining.removeIf { nxt ->
                    calculateIoU(first, nxt) >= iouMerge
                }
            }
            return selected
        }
        val selected = mutableListOf<BoundingBox>()
        for (cand in sorted) {
            var keep = true
            for (sel in selected) {
                if (cand.cls != sel.cls) continue
                if (calculateIoU(sel, cand) >= iouMerge) {
                    keep = false
                    break
                }
            }
            if (keep) selected.add(cand)
        }
        return selected
    }

    private fun calculateIoU(box1: BoundingBox, box2: BoundingBox): Float {
        val ix1 = maxOf(box1.x1, box2.x1)
        val iy1 = maxOf(box1.y1, box2.y1)
        val ix2 = minOf(box1.x2, box2.x2)
        val iy2 = minOf(box1.y2, box2.y2)
        val intersectionArea = maxOf(0F, ix2 - ix1) * maxOf(0F, iy2 - iy1)
        val area1 = (box1.x2 - box1.x1) * (box1.y2 - box1.y1)
        val area2 = (box2.x2 - box2.x1) * (box2.y2 - box2.y1)
        val union = area1 + area2 - intersectionArea
        return if (union > 0f) intersectionArea / union else 0f
    }

    private fun postNmsMax(): Int = Constants.YOLO_MAX_DET

    private fun postNmsMaxSingleClass(): Int = minOf(100, Constants.YOLO_MAX_DET)

    interface DetectorListener {
        fun onEmptyDetect()
        fun onDetect(boundingBoxes: List<BoundingBox>, inferenceTime: Long)
    }

    companion object {
        private const val PRE_NMS_MAX_SINGLE = 400
        private const val PRE_NMS_MAX_MULTI = 800
    }
}
