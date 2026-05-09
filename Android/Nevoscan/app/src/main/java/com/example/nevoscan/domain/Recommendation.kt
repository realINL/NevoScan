package com.example.nevoscan.domain

enum class RecommendationKind {
    Healthy,
    ShowDoctor,
    UrgentDoctor,
}

object Recommendation {

    fun getRecommendation(malignProbability: Float): RecommendationKind {
        val p = malignProbability
        return when {
            p < MILD_THRESHOLD -> RecommendationKind.Healthy
            p < URGENT_THRESHOLD -> RecommendationKind.ShowDoctor
            else -> RecommendationKind.UrgentDoctor
        }
    }

    private const val MILD_THRESHOLD = 0.3f
    private const val URGENT_THRESHOLD = 0.7f
}
