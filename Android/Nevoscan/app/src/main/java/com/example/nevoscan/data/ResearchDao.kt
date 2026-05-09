package com.example.nevoscan.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface ResearchDao {

    @Insert
    suspend fun insert(research: Research): Long

    @Update
    suspend fun update(research: Research)

    @Query("SELECT * FROM research WHERE id = :id LIMIT 1")
    suspend fun getById(id: Long): Research?

    @Query("SELECT * FROM research ORDER BY date DESC")
    fun observeAllSortedByDateDesc(): Flow<List<Research>>

    @Delete
    suspend fun delete(research: Research)
}
