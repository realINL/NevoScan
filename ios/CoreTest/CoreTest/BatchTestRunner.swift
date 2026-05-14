import Foundation
import UIKit

struct BatchRunSummary {
    let processedCount: Int
    let totalCount: Int
    let csvPath: String
    let masksDirectoryPath: String
    let skippedFiles: [String]
}

enum BatchRunnerError: LocalizedError {
    case imagesDirectoryNotFound(String)
    case noSupportedImages(String)
    case engineInitFailed(String)

    var errorDescription: String? {
        switch self {
        case .imagesDirectoryNotFound(let path):
            return "Папка Images не найдена по пути: \(path)"
        case .noSupportedImages(let path):
            return "В папке \(path) нет поддерживаемых изображений (jpg, jpeg, png)."
        case .engineInitFailed(let reason):
            return "Не удалось инициализировать CoreEngine: \(reason)"
        }
    }
}

enum BatchTestRunner {
    private static let supportedExtensions: Set<String> = ["jpg", "jpeg", "png"]

    static func run(onProgress: ((Int, Int) -> Void)? = nil) async throws -> BatchRunSummary {
        let imagesDir = imagesDirectoryURL()
        let fm = FileManager.default
        let resultDir = imagesDir.deletingLastPathComponent().appendingPathComponent("Result", isDirectory: true)
        let masksDir = resultDir.appendingPathComponent("masks", isDirectory: true)

        guard fm.fileExists(atPath: imagesDir.path) else {
            throw BatchRunnerError.imagesDirectoryNotFound(imagesDir.path)
        }

        let imageURLs = try fm.contentsOfDirectory(
            at: imagesDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

        guard !imageURLs.isEmpty else {
            throw BatchRunnerError.noSupportedImages(imagesDir.path)
        }

        let engine: CoreEngine
        do {
            engine = try CoreEngine()
        } catch {
            throw BatchRunnerError.engineInitFailed(error.localizedDescription)
        }

        try fm.createDirectory(at: resultDir, withIntermediateDirectories: true)
        try fm.createDirectory(at: masksDir, withIntermediateDirectories: true)

        let csvURL = resultDir.appendingPathComponent("results.csv", isDirectory: false)
        var csvRows = ["image_name,prob_mal,prob_ben,inference_sec"]
        var processedCount = 0
        var skippedFiles: [String] = []
        var visitedCount = 0

        onProgress?(0, imageURLs.count)

        for imageURL in imageURLs {
            defer {
                visitedCount += 1
                onProgress?(visitedCount, imageURLs.count)
            }

            guard let image = UIImage(contentsOfFile: imageURL.path) else {
                skippedFiles.append(imageURL.lastPathComponent)
                continue
            }

            do {
                let inferenceStarted = CFAbsoluteTimeGetCurrent()
                let result = try await engine.predict(on: image)
                let inferenceSec = CFAbsoluteTimeGetCurrent() - inferenceStarted

                let probMal = formattedProbability(result.malignProbability)
                let probBen = formattedProbability(result.benignProbability)
                let inferenceStr = String(format: "%.6f", inferenceSec)
                csvRows.append("\(imageURL.lastPathComponent),\(probMal),\(probBen),\(inferenceStr)")

                let maskName = "mask_\(imageURL.deletingPathExtension().lastPathComponent).png"
                let maskURL = masksDir.appendingPathComponent(maskName, isDirectory: false)
                if let segmentationImage = result.segmentationImage {
                    try saveMask(segmentationImage, to: maskURL)
                }

                processedCount += 1
            } catch {
                skippedFiles.append(imageURL.lastPathComponent)
            }
        }

        let csvData = (csvRows.joined(separator: "\n") + "\n").data(using: .utf8) ?? Data()
        try csvData.write(to: csvURL, options: .atomic)

        return BatchRunSummary(
            processedCount: processedCount,
            totalCount: imageURLs.count,
            csvPath: csvURL.path,
            masksDirectoryPath: masksDir.path,
            skippedFiles: skippedFiles
        )
    }

    private static func formattedProbability(_ value: Double) -> String {
        String(format: "%.6f", value)
    }

    private static func saveMask(_ image: UIImage, to url: URL) throws {
        guard let data = image.pngData() else {
            throw NSError(
                domain: "BatchTestRunner",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Не удалось сериализовать маску в PNG"]
            )
        }
        try data.write(to: url, options: .atomic)
    }

    private static func imagesDirectoryURL() -> URL {
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
        return projectRoot
            .deletingLastPathComponent()
            .appendingPathComponent("Images", isDirectory: true)
            .appendingPathComponent("Imgs", isDirectory: true)
    }
}
