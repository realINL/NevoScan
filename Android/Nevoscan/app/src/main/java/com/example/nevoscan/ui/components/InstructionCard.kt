package com.example.nevoscan.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.example.nevoscan.ui.theme.NevoscanColors

@Composable
fun InstructionCard(
    item: InstructionItem,
    modifier: Modifier = Modifier,
    compact: Boolean = false,
) {
    val horizontalPadding = if (compact) 8.dp else 16.dp
    val verticalPadding = if (compact) 8.dp else 16.dp
    val iconSize = if (compact) 28.dp else 36.dp
    val spacerW = if (compact) 10.dp else 16.dp

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(if (compact) 12.dp else 16.dp))
            .background(NevoscanColors.surface)
            .padding(horizontal = horizontalPadding, vertical = verticalPadding),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(
            imageVector = item.icon,
            contentDescription = null,
            modifier = Modifier.size(iconSize),
            tint = NevoscanColors.accent,
        )
        Spacer(modifier = Modifier.width(spacerW))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = item.title,
                style = if (compact) {
                    MaterialTheme.typography.bodyMedium
                } else {
                    MaterialTheme.typography.titleSmall
                },
                color = NevoscanColors.onSurface,
                maxLines = if (compact) 2 else Int.MAX_VALUE,
                overflow = TextOverflow.Ellipsis,
            )
            Spacer(modifier = Modifier.padding(top = if (compact) 2.dp else 4.dp))
            Text(
                text = item.description,
                style = if (compact) {
                    MaterialTheme.typography.labelSmall
                } else {
                    MaterialTheme.typography.bodyMedium
                },
                color = NevoscanColors.onSurfaceMuted,
                maxLines = if (compact) 2 else Int.MAX_VALUE,
                overflow = TextOverflow.Ellipsis,
            )
        }
    }
}
