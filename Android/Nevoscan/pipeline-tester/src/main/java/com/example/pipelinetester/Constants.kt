package com.example.pipelinetester

object Constants {
    const val SEGMENTATION_MODEL_PATH = "model.pte"
    const val CLASSIFICATION_MODEL_PATH = "classification_model.pte"

    const val SEGMENTATION_INPUT_SIZE = 256
    const val CLASSIFIER_INPUT_SIZE = 256
    const val CLASSIFIER_MASK_SIZE = 8

    const val SEGMENTATION_THRESHOLD = 0.5f
    const val MALIGNANCY_THRESHOLD = 0.3f
}
