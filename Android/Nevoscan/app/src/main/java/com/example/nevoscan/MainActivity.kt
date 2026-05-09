package com.example.nevoscan

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.example.nevoscan.ui.NevoscanApp
import com.example.nevoscan.ui.theme.NevoscanColors
import com.example.nevoscan.ui.theme.NevoscanTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            NevoscanTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = NevoscanColors.background,
                ) {
                    NevoscanApp()
                }
            }
        }
    }
}
