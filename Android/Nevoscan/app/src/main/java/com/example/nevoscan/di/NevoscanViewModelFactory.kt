package com.example.nevoscan.di

import android.app.Application
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.example.nevoscan.ui.AnalyzeViewModel
import com.example.nevoscan.ui.HistoryViewModel

class NevoscanViewModelFactory(
    private val application: Application,
    private val dependencies: AppDependencies,
) : ViewModelProvider.Factory {

    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return when {
            modelClass.isAssignableFrom(AnalyzeViewModel::class.java) ->
                AnalyzeViewModel(application, dependencies) as T
            modelClass.isAssignableFrom(HistoryViewModel::class.java) ->
                HistoryViewModel(application, dependencies) as T
            else -> throw IllegalArgumentException("Unknown ViewModel: ${modelClass.name}")
        }
    }
}
