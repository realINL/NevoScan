package com.example.nevoscan.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.nevoscan.R
import com.example.nevoscan.ui.components.MainButton
import com.example.nevoscan.ui.components.MyResearchsButton
import com.example.nevoscan.ui.components.NevoscanHeader
import com.example.nevoscan.ui.theme.NevoscanColors

@Composable
fun HomeScreen(
    onStartAnalysis: () -> Unit,
    onMyResearch: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier
            .fillMaxSize()
            .background(NevoscanColors.background)
            .padding(horizontal = 24.dp),
    ) {
        Spacer(modifier = Modifier.height(16.dp))
        NevoscanHeader()
        Spacer(modifier = Modifier.weight(0.35f))
        Column(
            modifier = Modifier
                .widthIn(max = 250.dp)
                .fillMaxWidth(),
        ) {
            Text(
                text = stringResource(R.string.home_title),
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.Medium,
                    color = NevoscanColors.onSurface,
                ),
            )
            Spacer(modifier = Modifier.height(48.dp))
            Text(
                text = stringResource(R.string.home_subtitle),
                style = MaterialTheme.typography.bodyLarge.copy(
                    color = NevoscanColors.onSurfaceMuted,
                    fontWeight = FontWeight.Normal,
                ),
            )
        }
        Spacer(modifier = Modifier.weight(0.25f))
        MainButton(
            text = stringResource(R.string.btn_start_analysis),
            onClick = onStartAnalysis,
        )
        Spacer(modifier = Modifier.height(8.dp))
        MyResearchsButton(
            text = stringResource(R.string.btn_my_researches),
            onClick = onMyResearch,
            modifier = Modifier.fillMaxWidth(),
        )
        Spacer(modifier = Modifier.height(32.dp))
    }
}
