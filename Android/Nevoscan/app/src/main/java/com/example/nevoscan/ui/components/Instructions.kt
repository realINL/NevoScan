package com.example.nevoscan.ui.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CenterFocusStrong
import androidx.compose.material.icons.outlined.FilterHdr
import androidx.compose.material.icons.outlined.PhotoCamera
import androidx.compose.material.icons.outlined.WbSunny
import androidx.compose.ui.graphics.vector.ImageVector

data class InstructionItem(
    val icon: ImageVector,
    val title: String,
    val description: String,
)

fun placeholderInstructions(): List<InstructionItem> = listOf(
    InstructionItem(
        icon = Icons.Outlined.WbSunny,
        title = "Хорошее освещение",
        description = "Снимайте при естественном или ровном свете без резких теней.",
    ),
    InstructionItem(
        icon = Icons.Outlined.CenterFocusStrong,
        title = "Родинка в фокусе и по центру",
        description = "Держите объект чётким и расположите его в центре кадра.",
    ),
    InstructionItem(
        icon = Icons.Outlined.PhotoCamera,
        title = "Без бликов",
        description = "Избегайте отражений и пересветов на коже.",
    ),
    InstructionItem(
        icon = Icons.Outlined.FilterHdr,
        title = "Нейтральный фон",
        description = "Проще всего на однотонном фоне без отвлекающих деталей.",
    ),
)
