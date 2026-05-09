package com.example.nevoscan.data

import android.graphics.Bitmap
import java.io.File
import java.io.FileOutputStream

class ImageStorage(
    private val researchesRoot: File,
) {

    fun saveForResearch(
        researchId: Long,
        original: Bitmap,
        cropped: Bitmap?,
        segmentation: Bitmap?,
    ): Triple<String, String?, String?> {
        val dir = File(researchesRoot, researchId.toString()).apply {
            mkdirs()
        }
        val originalFile = File(dir, ORIGINAL_NAME)
        original.compress(Bitmap.CompressFormat.JPEG, 92, FileOutputStream(originalFile))

        val croppedFile = cropped?.let { bmp ->
            File(dir, CROPPED_NAME).also {
                bmp.compress(Bitmap.CompressFormat.JPEG, 92, FileOutputStream(it))
            }
        }

        val segFile = segmentation?.let { bmp ->
            File(dir, SEG_NAME).also {
                bmp.compress(Bitmap.CompressFormat.JPEG, 92, FileOutputStream(it))
            }
        }

        return Triple(
            originalFile.absolutePath,
            croppedFile?.absolutePath,
            segFile?.absolutePath,
        )
    }

    fun deleteResearchFolder(researchId: Long) {
        val dir = File(researchesRoot, researchId.toString())
        if (dir.exists()) dir.deleteRecursively()
    }

    companion object {
        private const val ORIGINAL_NAME = "original.jpg"
        private const val CROPPED_NAME = "cropped.jpg"
        private const val SEG_NAME = "segmentation.jpg"

        fun researchesSubdir(filesDir: File): File =
            File(filesDir, "researches").apply { mkdirs() }
    }
}
