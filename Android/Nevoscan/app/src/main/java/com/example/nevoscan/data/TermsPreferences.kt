package com.example.nevoscan.data

import android.content.Context

class TermsPreferences(context: Context) {

    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun isTermsAccepted(): Boolean = prefs.getBoolean(KEY_TERMS_ACCEPTED, false)

    fun setTermsAccepted() {
        prefs.edit().putBoolean(KEY_TERMS_ACCEPTED, true).apply()
    }

    companion object {
        private const val PREFS_NAME = "nevoscan_prefs"
        private const val KEY_TERMS_ACCEPTED = "terms_accepted"
    }
}
