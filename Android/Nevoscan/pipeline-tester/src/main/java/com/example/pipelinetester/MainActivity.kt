package com.example.pipelinetester

import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : AppCompatActivity() {
    companion object {
        private const val EXTRA_AUTORUN = "autorun"
        private const val EXTRA_INPUT_DIR = "input_dir"
        private const val EXTRA_OUTPUT_DIR = "output_dir"
        private const val EXTRA_FINISH_ON_COMPLETE = "finish_on_complete"
    }

    private lateinit var logView: TextView
    private lateinit var runButton: Button

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 32, 32, 32)
        }
        runButton = Button(this).apply {
            text = "Запустить ML pipeline"
        }
        logView = TextView(this).apply {
            textSize = 14f
        }
        val scroll = ScrollView(this).apply {
            addView(logView)
        }
        root.addView(runButton)
        root.addView(
            scroll,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
        )
        setContentView(root)

        val runner = PipelineBatchRunner(applicationContext)
        val cliInputDirPath = intent.getStringExtra(EXTRA_INPUT_DIR)?.trim().orEmpty()
        val cliOutputDirPath = intent.getStringExtra(EXTRA_OUTPUT_DIR)?.trim().orEmpty()
        val runInputDir = if (cliInputDirPath.isNotEmpty()) java.io.File(cliInputDirPath) else runner.inputDir
        val runOutputDir = if (cliOutputDirPath.isNotEmpty()) java.io.File(cliOutputDirPath) else runner.outputDir
        val runOutputCsv = java.io.File(runOutputDir, "results.csv")
        val runMasksDir = java.io.File(runOutputDir, "output_masks")

        appendLog(
            buildString {
                appendLine("Ожидаемые директории:")
                appendLine("- Images: ${runInputDir.absolutePath}")
                appendLine("- CSV: ${runOutputCsv.absolutePath}")
                appendLine("- Masks: ${runMasksDir.absolutePath}")
                appendLine("")
//                appendLine("Ожидаемые модели в assets:")
//                appendLine("- ${Constants.SEGMENTATION_MODEL_PATH}")
//                appendLine("- ${Constants.CLASSIFICATION_MODEL_PATH}")
            }
        )

        val runAction = {
            runButton.isEnabled = false
            lifecycleScope.launch {
                val result = withContext(Dispatchers.IO) {
                    runner.runAll(
                        inputDir = runInputDir,
                        outputDir = runOutputDir,
                        log = ::appendLogThreadSafe
                    )
                }
                appendLog(
                    "Готово. Успешно: ${result.successCount}, ошибок: ${result.errorCount}."
                )
                runButton.isEnabled = true
                if (intent.getBooleanExtra(EXTRA_FINISH_ON_COMPLETE, false)) {
                    finish()
                }
            }
        }
        runButton.setOnClickListener { runAction() }

        if (intent.getBooleanExtra(EXTRA_AUTORUN, false)) {
            appendLog("CLI режим: автозапуск пайплайна")
            runAction()
        }
    }

    private fun appendLogThreadSafe(message: String) {
        runOnUiThread { appendLog(message) }
    }

    private fun appendLog(message: String) {
        logView.append(message)
        logView.append("\n")
    }
}
