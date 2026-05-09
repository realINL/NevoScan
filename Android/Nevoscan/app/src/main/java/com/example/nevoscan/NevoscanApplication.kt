package com.example.nevoscan

import android.app.Application
import com.example.nevoscan.di.AppDependencies

class NevoscanApplication : Application() {

    lateinit var container: AppContainer
        private set

    val dependencies: AppDependencies
        get() = container

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
    }
}
