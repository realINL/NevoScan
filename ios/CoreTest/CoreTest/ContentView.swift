//
//  ContentView.swift
//  CoreTest
//
//  Created by Илья Лебедев on 07.05.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var isRunning = false
    @State private var statusText = "Готово к запуску"
    @State private var finalReport = ""
    @State private var progressCurrent = 0
    @State private var progressTotal = 0

    var body: some View {
        VStack(spacing: 16) {
            Text("ML Pipeline Test")
                .font(.title2)
                .fontWeight(.semibold)

            Text(statusText)
                .font(.subheadline)
                .multilineTextAlignment(.center)

            if isRunning {
                ProgressView(
                    "Обработка \(progressCurrent) из \(max(progressTotal, 1))",
                    value: Double(progressCurrent),
                    total: Double(max(progressTotal, 1))
                )
                .frame(maxWidth: .infinity)
            }

            Button(action: runBatch) {
                Text(isRunning ? "Выполняется..." : "Запустить анализ")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)

            if !finalReport.isEmpty {
                ScrollView {
                    Text(finalReport)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                        .padding(10)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(maxHeight: 220)
            }
        }
        .padding()
    }

    private func runBatch() {
        isRunning = true
        finalReport = ""
        statusText = "Запуск анализа..."
        progressCurrent = 0
        progressTotal = 0

        Task {
            do {
                let summary = try await BatchTestRunner.run { current, total in
                    Task { @MainActor in
                        progressCurrent = current
                        progressTotal = total
                    }
                }
                statusText = "Анализ завершен"
                finalReport = makeReport(summary)
            } catch {
                statusText = "Ошибка при анализе"
                finalReport = error.localizedDescription
            }
            isRunning = false
        }
    }

    private func makeReport(_ summary: BatchRunSummary) -> String {
        var lines: [String] = [
            "Обработано фото: \(summary.processedCount) из \(summary.totalCount)",
            "CSV: \(summary.csvPath)",
            "Маски: \(summary.masksDirectoryPath)"
        ]

        if !summary.skippedFiles.isEmpty {
            lines.append("Пропущено файлов: \(summary.skippedFiles.count)")
        }

        return lines.joined(separator: "\n")
    }
}

#Preview {
    ContentView()
}
