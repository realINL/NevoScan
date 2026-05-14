package com.example.nevoscan.ui

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.nevoscan.data.TermsPreferences
import com.example.nevoscan.ui.screens.AnalyzeScreen
import com.example.nevoscan.ui.screens.HistoryScreen
import com.example.nevoscan.ui.screens.HomeScreen
import com.example.nevoscan.ui.screens.ResultScreen
import com.example.nevoscan.ui.screens.TermsOfUseScreen

@Composable
fun NevoscanApp(modifier: Modifier = Modifier) {
    val context = LocalContext.current
    val termsPreferences = remember { TermsPreferences(context) }
    var termsAccepted by remember { mutableStateOf(termsPreferences.isTermsAccepted()) }

    if (!termsAccepted) {
        TermsOfUseScreen(
            modifier = modifier.fillMaxSize(),
            onAccept = {
                termsPreferences.setTermsAccepted()
                termsAccepted = true
            },
        )
        return
    }

    val navController = rememberNavController()

    NavHost(
        modifier = modifier.fillMaxSize(),
        navController = navController,
        startDestination = "home",
    ) {
        composable("home") {
            HomeScreen(
                onStartAnalysis = { navController.navigate("analyze") },
                onMyResearch = { navController.navigate("history") },
                modifier = Modifier.fillMaxSize(),
            )
        }
        composable("analyze") {
            AnalyzeScreen(
                onNavigateToResult = { id ->
                    navController.navigate("result/$id")
                },
                onNavigateBack = { navController.popBackStack() },
                modifier = Modifier.fillMaxSize(),
            )
        }
        composable(
            route = "result/{id}",
            arguments = listOf(
                navArgument("id") { type = NavType.LongType },
            ),
        ) { entry ->
            val id = entry.arguments?.getLong("id") ?: return@composable
            ResultScreen(
                researchId = id,
                onClose = { navController.popBackStack() },
                modifier = Modifier.fillMaxSize(),
            )
        }
        composable("history") {
            HistoryScreen(
                onResearchClick = { id ->
                    navController.navigate("result/$id")
                },
                onBack = { navController.popBackStack() },
                modifier = Modifier.fillMaxSize(),
            )
        }
    }
}
