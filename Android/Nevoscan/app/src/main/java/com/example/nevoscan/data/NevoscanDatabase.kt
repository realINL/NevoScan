package com.example.nevoscan.data

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [Research::class],
    version = 1,
    exportSchema = false,
)
abstract class NevoscanDatabase : RoomDatabase() {

    abstract fun researchDao(): ResearchDao
}
