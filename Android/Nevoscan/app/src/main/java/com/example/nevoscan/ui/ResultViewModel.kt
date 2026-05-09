package com.example.nevoscan.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.nevoscan.data.Research
import com.example.nevoscan.di.AppDependencies
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ResultViewModelFactory(
    private val application: Application,
    private val dependencies: AppDependencies,
    private val researchId: Long,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        require(modelClass.isAssignableFrom(ResultViewModel::class.java))
        return ResultViewModel(application, dependencies, researchId) as T
    }
}

class ResultViewModel(
    application: Application,
    private val deps: AppDependencies,
    private val researchId: Long,
) : AndroidViewModel(application) {

    private val _research = MutableStateFlow<Research?>(null)
    val research: StateFlow<Research?> = _research.asStateFlow()

    init {
        viewModelScope.launch {
            _research.value = deps.researchRepository.getById(researchId)
        }
    }
}
