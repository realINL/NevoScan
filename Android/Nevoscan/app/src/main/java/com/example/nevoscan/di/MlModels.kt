package com.example.nevoscan.di

import com.example.nevoscan.ClassificationExecutor
import com.example.nevoscan.SegmentationExecutor
import com.example.nevoscan.YoloExecutor

data class MlModels(
    val yolo: YoloExecutor,
    val segmentation: SegmentationExecutor,
    val classification: ClassificationExecutor,
)
