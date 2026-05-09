package com.example.nevoscan

import android.content.Context
import android.graphics.Bitmap

class YoloExecutor(
    context: Context,
) {
    private val appContext = context.applicationContext

    private val detector = Detector(
        appContext,
        Constants.YOLO_ONNX_MODEL,
        Constants.YOLO_LABELS_FILE,
        object : Detector.DetectorListener {
            override fun onEmptyDetect() {}

            override fun onDetect(boundingBoxes: List<BoundingBox>, inferenceTime: Long) {}
        },
    )

    @Volatile
    var isReady: Boolean = false
        private set

    fun setup() {
        isReady = detector.setup()
    }

    fun ensureReady(): Boolean {
        if (isReady) return true
        synchronized(this) {
            if (isReady) return true
            setup()
            return isReady
        }
    }

    fun detectFirstBox(bitmap: Bitmap): BoundingBox? {
        if (!isReady) return null
        val list = detector.detectSync(bitmap) ?: return null
        return list.firstOrNull()
    }
}
