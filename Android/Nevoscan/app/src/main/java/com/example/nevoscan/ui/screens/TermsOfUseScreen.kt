package com.example.nevoscan.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.MedicalServices
import androidx.compose.material.icons.filled.PhoneAndroid
import androidx.compose.material.icons.outlined.BackHand
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.nevoscan.R
import com.example.nevoscan.ui.components.MainButton
import com.example.nevoscan.ui.theme.NevoscanColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TermsOfUseScreen(
    onAccept: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val context = LocalContext.current
    var policyText by remember { mutableStateOf("") }
    var showFullPolicy by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        policyText = runCatching {
            context.assets.open("terms_of_use.txt").bufferedReader().use { it.readText() }
        }.getOrDefault("")
    }

    val chevronRotation by animateFloatAsState(
        targetValue = if (showFullPolicy) 90f else 0f,
        label = "policyChevron",
    )

    BackHandler(enabled = true) { /* согласие обязательно */ }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        containerColor = NevoscanColors.background,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.terms_title),
                        style = MaterialTheme.typography.titleMedium,
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = NevoscanColors.background,
                    titleContentColor = NevoscanColors.onSurface,
                ),
            )
        },
        bottomBar = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(NevoscanColors.surface)
                    .padding(horizontal = 16.dp, vertical = 12.dp),
            ) {
                MainButton(
                    text = stringResource(R.string.terms_agree),
                    onClick = onAccept,
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = stringResource(R.string.terms_agree_disclaimer),
                    style = MaterialTheme.typography.bodySmall,
                    color = NevoscanColors.onSurfaceMuted,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 16.dp),
        ) {
            Icon(
                imageVector = Icons.Outlined.BackHand,
                contentDescription = null,
                modifier = Modifier
                    .padding(top = 8.dp)
                    .size(70.dp)
                    .align(Alignment.CenterHorizontally),
                tint = NevoscanColors.accent,
            )
            Spacer(modifier = Modifier.height(16.dp))
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = NevoscanColors.surface),
                elevation = CardDefaults.cardElevation(defaultElevation = 0.dp),
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = stringResource(R.string.terms_basic_provisions),
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.SemiBold),
                        color = NevoscanColors.onSurface,
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    PolicyHighlightRow(
                        icon = Icons.Filled.MedicalServices,
                        title = stringResource(R.string.terms_highlight1_title),
                        description = stringResource(R.string.terms_highlight1_description),
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    PolicyHighlightRow(
                        icon = Icons.Filled.PhoneAndroid,
                        title = stringResource(R.string.terms_highlight2_title),
                        description = stringResource(R.string.terms_highlight2_description),
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    PolicyHighlightRow(
                        icon = Icons.Filled.Lock,
                        title = stringResource(R.string.terms_highlight3_title),
                        description = stringResource(R.string.terms_highlight3_description),
                    )
                }
            }
            Spacer(modifier = Modifier.height(24.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clipCardClickable { showFullPolicy = !showFullPolicy }
                    .padding(vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = stringResource(R.string.terms_policy_link),
                    style = MaterialTheme.typography.bodyLarge,
                    color = NevoscanColors.onSurface,
                    modifier = Modifier.weight(1f),
                )
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    modifier = Modifier.rotate(chevronRotation),
                    tint = NevoscanColors.onSurfaceMuted,
                )
            }
            AnimatedVisibility(visible = showFullPolicy && policyText.isNotBlank()) {
                Text(
                    text = policyText.trim(),
                    style = MaterialTheme.typography.bodySmall,
                    color = NevoscanColors.onSurfaceMuted,
                    modifier = Modifier.padding(bottom = 24.dp),
                )
            }
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@Composable
private fun PolicyHighlightRow(
    icon: ImageVector,
    title: String,
    description: String,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.Top,
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            modifier = Modifier.size(28.dp),
            tint = NevoscanColors.accent,
        )
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                color = NevoscanColors.onSurface,
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = description,
                style = MaterialTheme.typography.bodyMedium,
                color = NevoscanColors.onSurfaceMuted,
            )
        }
    }
}

private fun Modifier.clipCardClickable(onClick: () -> Unit): Modifier =
    this.then(
        Modifier
            .background(NevoscanColors.surface, RoundedCornerShape(12.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp),
    )
