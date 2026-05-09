package com.example.nevoscan.ui.components

import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.example.nevoscan.ui.theme.NevoscanColors

@Composable
fun NevoscanHeader(
    modifier: Modifier = Modifier,
    title: String = "NevoScan",
) {
    Text(
        text = title,
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 12.dp),
        style = MaterialTheme.typography.headlineSmall.copy(
            color = NevoscanColors.accent,
            fontWeight = FontWeight.Bold,
        ),
        textAlign = TextAlign.Center,
    )
}
