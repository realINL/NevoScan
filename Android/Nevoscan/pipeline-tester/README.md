# Pipeline Tester

Отдельный Kotlin/Android модуль для batch-тестирования ML пайплайна.

## Что делает

- читает изображения из папки `Images`;
- прогоняет сегментацию и классификацию;
- сохраняет CSV `results.csv` в формате `image_name,prob_mal,prob_ben`;
- сохраняет маски в PNG в папку `output_masks`.

## Где находятся папки на устройстве

Приложение использует директорию:

`/Android/data/com.example.pipelinetester/files/`

- вход: `Images`
- выход: `PipelineOutput/results.csv`
- маски: `PipelineOutput/output_masks`

## Важно

В `assets` модуля должны быть модели:

- `model.pte`
- `classification_model.pte`

Если моделей нет, запуск завершится с ошибкой.

## CLI запуск через ADB

Можно запускать без нажатия кнопки (автоматически), передавая параметры в `Intent`.

### 1) Установить APK

```bash
adb install -r pipeline-tester/build/outputs/apk/debug/pipeline-tester-debug.apk
```

### 2) Подготовить входные изображения

Пример для директории по умолчанию:

```bash
adb push ./Images /sdcard/Android/data/com.example.pipelinetester/files/
```

### 3) Запустить пайплайн в CLI-режиме

```bash
adb shell am start -n com.example.pipelinetester/.MainActivity \
  --ez autorun true \
  --ez finish_on_complete true
```

### 4) Забрать результаты

```bash
adb pull /sdcard/Android/data/com.example.pipelinetester/files/PipelineOutput ./PipelineOutput
```

### Кастомные пути (опционально)

Можно передать абсолютные пути:

```bash
adb shell am start -n com.example.pipelinetester/.MainActivity \
  --ez autorun true \
  --ez finish_on_complete true \
  --es input_dir "/sdcard/MyImages" \
  --es output_dir "/sdcard/MyPipelineOutput"
```

Поддерживаемые extras:

- `autorun` (`boolean`) - автоматический старт пайплайна
- `finish_on_complete` (`boolean`) - закрыть activity после завершения
- `input_dir` (`string`) - абсолютный путь к входной папке
- `output_dir` (`string`) - абсолютный путь к выходной папке
