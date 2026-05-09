package com.example.pipelinetester

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.File
import java.io.FileOutputStream

data class BatchRunResult(
    val successCount: Int,
    val errorCount: Int
)

class PipelineBatchRunner(context: Context) {
    private val appContext = context.applicationContext
    private val defaultBaseDir = appContext.getExternalFilesDir(null)
        ?: appContext.filesDir
    val inputDir: File = File(defaultBaseDir, "Images")
    val outputDir: File = File(defaultBaseDir, "PipelineOutput")
    val outputCsv: File = File(outputDir, "results.csv")
    val masksDir: File = File(outputDir, "output_masks")

    private val segmentationExecutor = SegmentationExecutor(
        appContext,
        Constants.SEGMENTATION_MODEL_PATH
    )
    private val classificationExecutor = ClassificationExecutor(
        appContext,
        Constants.CLASSIFICATION_MODEL_PATH
    )

    fun runAll(log: (String) -> Unit): BatchRunResult {
        return runAll(inputDir, outputDir, log)
    }

    fun runAll(
        inputDir: File,
        outputDir: File,
        log: (String) -> Unit
    ): BatchRunResult {
        val outputCsv = File(outputDir, "results.csv")
        val masksDir = File(outputDir, "output_masks")
        inputDir.mkdirs()
        outputDir.mkdirs()
        masksDir.mkdirs()

        val images = inputDir.listFiles()
            ?.filter { it.isFile && it.extension.lowercase() in setOf("jpg", "jpeg", "png", "bmp", "webp") }
            ?.sortedBy { it.name }
            .orEmpty()

        if (images.isEmpty()) {
            log("Папка Images пуста: ${inputDir.absolutePath}")
            return BatchRunResult(0, 0)
        }

        log("Загрузка моделей...")
        segmentationExecutor.setup()
        classificationExecutor.setup()
        log("Найдено изображений: ${images.size}")

        outputCsv.writeText("image_name,prob_mal,prob_ben\n")
        var success = 0
        var errors = 0

        for (imageFile in images) {
            try {
                val source = BitmapFactory.decodeFile(imageFile.absolutePath)
                    ?: error("Не удалось прочитать изображение")
                val workBmp = prepareImageLikeMainPyBeforeSegmentation(source)
                try {
                    val segmented = segmentationExecutor.segment(workBmp)
                    val cls = classificationExecutor.classify(
                        image = workBmp,
                        segMask = segmented.mask,
                        segMaskWidth = segmented.maskWidth,
                        segMaskHeight = segmented.maskHeight
                    )
                    saveMask(
                        imageName = imageFile.nameWithoutExtension,
                        mask = segmented.mask,
                        maskW = segmented.maskWidth,
                        maskH = segmented.maskHeight,
                        targetW = workBmp.width,
                        targetH = workBmp.height
                    )
                    outputCsv.appendText("${imageFile.name},${cls.probMalign},${cls.probBenign}\n")
                    success++
                    log("OK: ${imageFile.name}")
                } finally {
                    if (workBmp !== source) {
                        workBmp.recycle()
                    }
                    source.recycle()
                }
            } catch (t: Throwable) {
                errors++
                log("ERR: ${imageFile.name}: ${t.message}")
            }
        }

        return BatchRunResult(success, errors)
    }

    private fun saveMask(
        imageName: String,
        mask: ByteArray,
        maskW: Int,
        maskH: Int,
        targetW: Int,
        targetH: Int
    ) {
        val fullResMask = binaryMaskUpscaleNearest(mask, maskW, maskH, targetW, targetH)
        val maskBitmap = renderBinaryMaskGrayscale(fullResMask, targetW, targetH)
        val outFile = File(masksDir, "${imageName}_mask.png")
        FileOutputStream(outFile).use { fos ->
            maskBitmap.compress(Bitmap.CompressFormat.PNG, 100, fos)
        }
        maskBitmap.recycle()
    }
}
