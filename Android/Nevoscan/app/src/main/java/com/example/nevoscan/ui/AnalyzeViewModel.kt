package com.example.nevoscan.ui

import android.app.Application
import android.graphics.Bitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.nevoscan.R
import com.example.nevoscan.di.AppDependencies
import com.example.nevoscan.binaryMaskUpscaleNearest
import com.example.nevoscan.cropBitmapWithNormalizedBox
import com.example.nevoscan.drawBoundingBoxOnBitmap
import com.example.nevoscan.prepareImageLikeMainPyBeforeSegmentation
import com.example.nevoscan.renderBinaryMaskGrayscale
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

data class AnalyzeUiState(
    val selectedImage: Bitmap? = null,

    val originalForStorage: Bitmap? = null,

    val lesionCropForPipeline: Bitmap? = null,
    val canStartAnalysis: Boolean = false,
    val presentInstructions: Boolean = true,
    val isLoading: Boolean = false,
    val isYoloBusy: Boolean = false,
    val lastResearchId: Long? = null,
    val error: String? = null,
    val transientMessage: String? = null,
    val showNoDetectionAlert: Boolean = false,
)

class AnalyzeViewModel(
    application: Application,
    private val deps: AppDependencies,
) : AndroidViewModel(application) {

    private val _uiState = MutableStateFlow(AnalyzeUiState())
    val uiState: StateFlow<AnalyzeUiState> = _uiState.asStateFlow()

    fun setPresentInstructions(show: Boolean) {
        _uiState.update { it.copy(presentInstructions = show) }
    }

    fun consumeTransientMessage() {
        _uiState.update { it.copy(transientMessage = null) }
    }

    fun dismissNoDetectionAlert() {
        _uiState.update { it.copy(showNoDetectionAlert = false) }
    }

    private fun recycleSelectionBitmaps(showing: AnalyzeUiState) {
        val orig = showing.originalForStorage
        val sel = showing.selectedImage
        val crop = showing.lesionCropForPipeline
        if (sel != null && sel !== orig && !sel.isRecycled) sel.recycle()
        if (crop != null && crop !== orig && crop !== sel && !crop.isRecycled) crop.recycle()
        if (orig != null && !orig.isRecycled) orig.recycle()
    }


    fun onImageChosen(bitmap: Bitmap) {
        recycleSelectionBitmaps(_uiState.value)
        viewModelScope.launch {
            _uiState.update {
                it.copy(
                    isYoloBusy = true,
                    error = null,
                    lastResearchId = null,
                    selectedImage = null,
                    originalForStorage = null,
                    lesionCropForPipeline = null,
                    canStartAnalysis = false,
                    transientMessage = null,
                    showNoDetectionAlert = false,
                    presentInstructions = false,
                )
            }
            val app = getApplication<Application>()
            val result = withContext(Dispatchers.Default) {
                val full = bitmap.copy(Bitmap.Config.ARGB_8888, true)
                    ?: return@withContext ImageProcessResult(
                        full = null,
                        preview = null,
                        crop = null,
                        ok = false,
                        message = app.getString(R.string.error_bitmap_copy),
                    )
                if (!deps.mlModels.yolo.ensureReady()) {
                    return@withContext ImageProcessResult(
                        full = full,
                        preview = full,
                        crop = null,
                        ok = false,
                        message = app.getString(R.string.yolo_model_missing),
                    )
                }
                val box = deps.mlModels.yolo.detectFirstBox(full)
                if (box == null) {
                    return@withContext ImageProcessResult(
                        full = full,
                        preview = full,
                        crop = null,
                        ok = false,
                        message = null,
                        noDetection = true,
                    )
                }
                val preview = drawBoundingBoxOnBitmap(full, box)
                val cropped = cropBitmapWithNormalizedBox(full, box)
                val work = prepareImageLikeMainPyBeforeSegmentation(cropped)
                ImageProcessResult(
                    full = full,
                    preview = preview,
                    crop = work,
                    ok = true,
                    message = null,
                )
            }
            _uiState.update {
                it.copy(
                    isYoloBusy = false,
                    originalForStorage = result.full,
                    selectedImage = result.preview ?: result.full,
                    lesionCropForPipeline = result.crop,
                    canStartAnalysis = result.ok,
                    transientMessage = result.message,
                    showNoDetectionAlert = result.noDetection,
                )
            }
        }
    }

    fun resetSelectedImage() {
        recycleSelectionBitmaps(_uiState.value)
        _uiState.update {
            it.copy(
                selectedImage = null,
                originalForStorage = null,
                lesionCropForPipeline = null,
                canStartAnalysis = false,
                error = null,
                lastResearchId = null,
                transientMessage = null,
                showNoDetectionAlert = false,
                presentInstructions = true,
            )
        }
    }

    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    fun analyze(onSuccess: (Long) -> Unit) {
        val original = _uiState.value.originalForStorage ?: return
        val lesion = _uiState.value.lesionCropForPipeline ?: return
        if (!_uiState.value.canStartAnalysis) return

        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }
            val pipeline = runCatching {
                withContext(Dispatchers.Default) {
                    val workBmp = lesion
                    try {
                        val segmented = deps.mlModels.segmentation.segment(workBmp)
                        val maskFullRes = binaryMaskUpscaleNearest(
                            segmented.mask,
                            segmented.maskWidth,
                            segmented.maskHeight,
                            workBmp.width,
                            workBmp.height,
                        )
                        val maskBitmap = renderBinaryMaskGrayscale(
                            maskFullRes,
                            workBmp.width,
                            workBmp.height,
                        )

                        val cls = runCatching {
                            deps.mlModels.classification.classify(
                                image = workBmp,
                                segMask = segmented.mask,
                                segMaskWidth = segmented.maskWidth,
                                segMaskHeight = segmented.maskHeight,
                            )
                        }.getOrNull()

                        val benign = cls?.probBenign ?: 0.5f
                        val malign = cls?.probMalign ?: 0.5f

                        val croppedCopy = workBmp.copy(Bitmap.Config.ARGB_8888, false)
                            ?: error("Не удалось подготовить изображение для сохранения")

                        Triple(croppedCopy, maskBitmap, benign to malign)
                    } finally {
                    }
                }
            }

            pipeline.onSuccess { (croppedBitmap, maskBitmap, probs) ->
                val benign = probs.first
                val malign = probs.second
                val id = runCatching {
                    withContext(Dispatchers.IO) {
                        deps.researchRepository.insertWithImages(
                            original = original,
                            cropped = croppedBitmap,
                            segmentation = maskBitmap,
                            benignProbability = benign,
                            malignProbability = malign,
                        )
                    }
                }.fold(
                    onSuccess = { it },
                    onFailure = { e ->
                        croppedBitmap.recycle()
                        maskBitmap.recycle()
                        _uiState.update {
                            it.copy(
                                isLoading = false,
                                error = e.message ?: e.javaClass.simpleName,
                            )
                        }
                        return@launch
                    },
                )

                croppedBitmap.recycle()
                maskBitmap.recycle()

                _uiState.update { it.copy(isLoading = false, lastResearchId = id) }
                onSuccess(id)
            }.onFailure { e ->
                _uiState.update {
                    it.copy(
                        isLoading = false,
                        error = e.message ?: e.javaClass.simpleName,
                    )
                }
            }
        }
    }
}

private data class ImageProcessResult(
    val full: Bitmap?,
    val preview: Bitmap?,
    val crop: Bitmap?,
    val ok: Boolean,
    val message: String?,
    val noDetection: Boolean = false,
)

fun AnalyzeViewModel.setSelectedImageFromCompose(image: androidx.compose.ui.graphics.ImageBitmap?) {
    val bmp = image?.asAndroidBitmap() ?: return
    onImageChosen(bmp)
}
