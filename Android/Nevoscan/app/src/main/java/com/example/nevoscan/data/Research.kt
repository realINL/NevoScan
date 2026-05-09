package com.example.nevoscan.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "research")
data class Research(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val date: Long,
    val originalImagePath: String,
    val croppedImagePath: String?,
    val segmentationImagePath: String?,
    val benignProbability: Float,
    val malignProbability: Float,
)
