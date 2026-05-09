package com.example.nevoscan

object Constants {
    const val SEGMENTATION_MODEL_PATH = "model.pte"

    const val CLASSIFICATION_MODEL_PATH = "classification_model.pte"

    const val SEGMENTATION_INPUT_SIZE = 256

    const val CLASSIFIER_INPUT_SIZE = 256

    const val CLASSIFIER_MASK_SIZE = 8

    const val CLASSIFIER_MASK_CHANNELS = 2048

    const val SEGMENTATION_THRESHOLD = 0.5f

    const val MALIGNANCY_THRESHOLD = 0.3f

    const val YOLO_ONNX_MODEL = "yolo.onnx"

    const val YOLO_LABELS_FILE = "lables.txt"

    const val YOLO_LETTERBOX_PAD = 114

    const val INFERENCE_CONF = 0.4f

    const val INFERENCE_IOU_NMS = 0.8f

    const val YOLO_AGNOSTIC_NMS = true

    const val YOLO_MAX_DET = 1
}