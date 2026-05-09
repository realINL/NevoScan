package com.example.nevoscan.data

import android.graphics.Bitmap
import androidx.room.withTransaction
import kotlinx.coroutines.flow.Flow

class ResearchRepository(
    private val database: NevoscanDatabase,
    private val dao: ResearchDao,
    private val imageStorage: ImageStorage,
) {

    suspend fun insertWithImages(
        original: Bitmap,
        cropped: Bitmap?,
        segmentation: Bitmap?,
        benignProbability: Float,
        malignProbability: Float,
    ): Long {
        val now = System.currentTimeMillis()
        return database.withTransaction {
            val id = dao.insert(
                Research(
                    date = now,
                    originalImagePath = PENDING_MARKER,
                    croppedImagePath = null,
                    segmentationImagePath = null,
                    benignProbability = benignProbability,
                    malignProbability = malignProbability,
                ),
            )
            val paths = imageStorage.saveForResearch(
                researchId = id,
                original = original,
                cropped = cropped,
                segmentation = segmentation,
            )
            dao.update(
                Research(
                    id = id,
                    date = now,
                    originalImagePath = paths.first,
                    croppedImagePath = paths.second,
                    segmentationImagePath = paths.third,
                    benignProbability = benignProbability,
                    malignProbability = malignProbability,
                ),
            )
            id
        }
    }

    suspend fun getById(id: Long): Research? = dao.getById(id)

    fun observeAllSorted(): Flow<List<Research>> =
        dao.observeAllSortedByDateDesc()

    suspend fun deleteResearch(research: Research) {
        dao.delete(research)
        imageStorage.deleteResearchFolder(research.id)
    }

    companion object {
        private const val PENDING_MARKER = "__pending__"
    }
}
