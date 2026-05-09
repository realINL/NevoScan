package com.example.nevoscan

import android.app.Application
import androidx.room.Room
import com.example.nevoscan.data.ImageStorage
import com.example.nevoscan.data.NevoscanDatabase
import com.example.nevoscan.data.ResearchDao
import com.example.nevoscan.data.ResearchRepository
import com.example.nevoscan.di.AppDependencies
import com.example.nevoscan.di.MlModels
import java.util.concurrent.Executors

class AppContainer(application: Application) : AppDependencies {

    private val executor = Executors.newSingleThreadExecutor()

    val database: NevoscanDatabase = Room.databaseBuilder(
        application,
        NevoscanDatabase::class.java,
        "nevoscan.db",
    ).build()

    private val researchesDir = ImageStorage.researchesSubdir(application.filesDir)
    private val imageStorage: ImageStorage = ImageStorage(researchesDir)

    private val researchDao: ResearchDao = database.researchDao()

    override val mlModels: MlModels = MlModels(
        yolo = YoloExecutor(application),
        segmentation = SegmentationExecutor(
            application,
            Constants.SEGMENTATION_MODEL_PATH,
        ),
        classification = ClassificationExecutor(
            application,
            Constants.CLASSIFICATION_MODEL_PATH,
        ),
    )

    override val researchRepository: ResearchRepository = ResearchRepository(
        database = database,
        dao = researchDao,
        imageStorage = imageStorage,
    )

    init {
        executor.execute {
            runCatching { mlModels.segmentation.setup() }
            runCatching { mlModels.classification.setup() }
            runCatching { mlModels.yolo.setup() }
        }
    }
}
