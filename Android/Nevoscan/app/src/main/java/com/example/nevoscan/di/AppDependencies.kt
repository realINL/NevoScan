package com.example.nevoscan.di

import com.example.nevoscan.data.ResearchRepository

/**
 * Корневой контракт DI
 */
interface AppDependencies {
    val mlModels: MlModels
    val researchRepository: ResearchRepository
}
