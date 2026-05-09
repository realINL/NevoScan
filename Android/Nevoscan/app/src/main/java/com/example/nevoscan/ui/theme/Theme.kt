package com.example.nevoscan.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val NevoscanLightScheme = lightColorScheme(
    primary = NevoscanColors.accent,
    onPrimary = NevoscanColors.surface,
    secondary = NevoscanColors.accent,
    onSecondary = NevoscanColors.surface,
    tertiary = NevoscanColors.disclaimerYellow,
    background = NevoscanColors.background,
    surface = NevoscanColors.surface,
    onSurface = NevoscanColors.onSurface,
    onSurfaceVariant = NevoscanColors.onSurfaceMuted,
    surfaceVariant = NevoscanColors.background,
)

@Composable
fun NevoscanTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = NevoscanLightScheme,
        typography = Typography,
        content = content
    )
}
