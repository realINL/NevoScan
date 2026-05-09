package com.example.nevoscan.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.nevoscan.data.Research
import com.example.nevoscan.di.AppDependencies
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class HistoryViewModel(
    application: Application,
    deps: AppDependencies,
) : AndroidViewModel(application) {

    private val repository = deps.researchRepository

    val researches: StateFlow<List<Research>> =
        repository.observeAllSorted().stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = emptyList(),
        )

    fun deleteResearch(research: Research) {
        viewModelScope.launch {
            repository.deleteResearch(research)
        }
    }
}
