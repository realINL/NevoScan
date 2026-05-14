package com.example.nevoscan.ui.screens

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ExpandLess
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.nevoscan.NevoscanApplication
import com.example.nevoscan.R
import com.example.nevoscan.di.NevoscanViewModelFactory
import com.example.nevoscan.ui.AnalyzeViewModel
import com.example.nevoscan.ui.setSelectedImageFromCompose
import com.example.nevoscan.ui.util.decodeImageBitmapFromUri
import com.example.nevoscan.ui.util.decodeImageBitmapFromFile
import com.example.nevoscan.ui.components.InputButton
import com.example.nevoscan.ui.components.InstructionCard
import com.example.nevoscan.ui.components.ResetButton
import com.example.nevoscan.ui.components.placeholderInstructions
import com.example.nevoscan.ui.theme.NevoscanColors
import java.io.File
import kotlinx.coroutines.launch

private const val FileProviderAuthority = "com.example.nevoscan.fileprovider"

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AnalyzeScreen(
    onNavigateToResult: (Long) -> Unit,
    onNavigateBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val application = LocalContext.current.applicationContext as NevoscanApplication
    val viewModel: AnalyzeViewModel = viewModel(
        factory = NevoscanViewModelFactory(application, application.dependencies),
    )
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }
    val state by viewModel.uiState.collectAsStateWithLifecycle()
    val instructions = remember { placeholderInstructions() }

    LaunchedEffect(state.transientMessage) {
        val msg = state.transientMessage ?: return@LaunchedEffect
        snackbarHostState.showSnackbar(msg)
        viewModel.consumeTransientMessage()
    }

    var pendingCaptureFile by remember { mutableStateOf<File?>(null) }
    val pickImageLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia(),
        onResult = { uri: Uri? ->
            if (uri != null) {
                val bmp = context.decodeImageBitmapFromUri(uri)
                viewModel.setSelectedImageFromCompose(bmp)
            }
        },
    )

    val takePictureLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicture(),
    ) { success ->
        val file = pendingCaptureFile
        if (success && file != null && file.exists()) {
            val bmp = context.decodeImageBitmapFromFile(file)
            viewModel.setSelectedImageFromCompose(bmp)
        }
        pendingCaptureFile = null
    }

    val requestCameraPermission = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
    ) { granted ->
        if (granted) {
            val file = File.createTempFile("capture_", ".jpg", context.cacheDir)
            pendingCaptureFile = file
            val uri = FileProvider.getUriForFile(context, FileProviderAuthority, file)
            takePictureLauncher.launch(uri)
        } else {
            scope.launch {
                snackbarHostState.showSnackbar(context.getString(R.string.camera_permission_denied))
            }
        }
    }

    fun launchCamera() {
        when {
            ContextCompat.checkSelfPermission(context, android.Manifest.permission.CAMERA) ==
                android.content.pm.PackageManager.PERMISSION_GRANTED -> {
                val file = File.createTempFile("capture_", ".jpg", context.cacheDir)
                pendingCaptureFile = file
                takePictureLauncher.launch(
                    FileProvider.getUriForFile(context, FileProviderAuthority, file),
                )
            }
            else -> requestCameraPermission.launch(android.Manifest.permission.CAMERA)
        }
    }

    if (state.showNoDetectionAlert) {
        AlertDialog(
            onDismissRequest = { viewModel.dismissNoDetectionAlert() },
            title = { Text(stringResource(R.string.detection_no_lesion_title)) },
            text = { Text(stringResource(R.string.detection_no_lesion)) },
            confirmButton = {
                TextButton(onClick = { viewModel.dismissNoDetectionAlert() }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
        )
    }

    if (state.error != null) {
        AlertDialog(
            onDismissRequest = { viewModel.clearError() },
            title = { Text(stringResource(R.string.error_processing_title)) },
            text = { Text(state.error ?: "") },
            confirmButton = {
                TextButton(onClick = { viewModel.clearError() }) {
                    Text(stringResource(android.R.string.ok))
                }
            },
        )
    }

    Scaffold(
        modifier = modifier.fillMaxSize(),
        containerColor = NevoscanColors.background,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = null,
                            tint = NevoscanColors.accent,
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = NevoscanColors.background,
                ),
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 24.dp),
        ) {
            if (!state.isLoading) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { viewModel.setPresentInstructions(!state.presentInstructions) }
                        .padding(vertical = 6.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = stringResource(R.string.analyze_recommendations_title),
                        style = MaterialTheme.typography.titleMedium,
                        color = NevoscanColors.onSurface,
                    )
                    Icon(
                        imageVector = if (state.presentInstructions) Icons.Filled.ExpandLess else Icons.Filled.ExpandMore,
                        contentDescription = null,
                        tint = NevoscanColors.accent,
                    )
                }

                AnimatedVisibility(visible = state.presentInstructions) {
                    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        instructions.forEach { item ->
                            InstructionCard(item = item, compact = true)
                        }
                    }
                }
            }

            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                contentAlignment = Alignment.Center,
            ) {
                when {
                    state.isYoloBusy -> {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(20.dp),
                        ) {
                            CircularProgressIndicator(
                                modifier = Modifier.scale(1.6f),
                                color = NevoscanColors.accent,
                            )
                            Text(
                                text = stringResource(R.string.detection_in_progress),
                                style = MaterialTheme.typography.bodyLarge,
                                color = NevoscanColors.onSurfaceMuted,
                            )
                        }
                    }

                    state.isLoading -> {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(20.dp),
                        ) {
                            CircularProgressIndicator(
                                modifier = Modifier.scale(1.6f),
                                color = NevoscanColors.accent,
                            )
                            Text(
                                text = stringResource(R.string.analyze_in_progress),
                                style = MaterialTheme.typography.bodyLarge,
                                color = NevoscanColors.onSurfaceMuted,
                            )
                        }
                    }

                    state.selectedImage == null -> {
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            verticalArrangement = Arrangement.spacedBy(12.dp),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            Text(
                                text = stringResource(R.string.analyze_pick_source),
                                style = MaterialTheme.typography.bodyLarge,
                                color = NevoscanColors.onSurfaceMuted,
                                modifier = Modifier.padding(bottom = 4.dp),
                            )
                            InputButton(
                                text = stringResource(R.string.btn_gallery),
                                onClick = {
                                    pickImageLauncher.launch(
                                        PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly),
                                    )
                                },
                            )
                            InputButton(
                                text = stringResource(R.string.btn_camera),
                                onClick = { launchCamera() },
                            )
                        }
                    }

                    else -> {
                        Column(
                            modifier = Modifier.fillMaxSize(),
                            horizontalAlignment = Alignment.CenterHorizontally,
                        ) {
                            BoxWithConstraints(
                                modifier = Modifier
                                    .weight(1f)
                                    .fillMaxWidth(),
                            ) {
                                val reserveButtons = 128.dp
                                val roomForImage = (maxHeight - reserveButtons).coerceAtLeast(96.dp)
                                val frac =
                                    if (state.presentInstructions) 0.5f else 0.94f
                                val imageMaxHeight = roomForImage * frac
                                Box(
                                    modifier = Modifier.fillMaxSize(),
                                    contentAlignment = Alignment.Center,
                                ) {
                                    Image(
                                        bitmap = state.selectedImage!!.asImageBitmap(),
                                        contentDescription = null,
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .widthIn(max = 320.dp)
                                            .heightIn(max = imageMaxHeight)
                                            .clip(RoundedCornerShape(25.dp)),
                                        contentScale = ContentScale.Fit,
                                    )
                                }
                            }
                            Column(
                                modifier = Modifier.fillMaxWidth(),
                                verticalArrangement = Arrangement.spacedBy(10.dp),
                                horizontalAlignment = Alignment.CenterHorizontally,
                            ) {
                                ResetButton(
                                    text = stringResource(R.string.btn_reset),
                                    onClick = { viewModel.resetSelectedImage() },
                                )
                                InputButton(
                                    text = stringResource(R.string.btn_start_analyze),
                                    onClick = {
                                        viewModel.analyze { id ->
                                            onNavigateToResult(id)
                                        }
                                    },
                                    enabled = state.canStartAnalysis && !state.isLoading,
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}
