//
//  AppShortcuts.swift
//  W8Trackr
//
//  Siri Shortcuts integration using App Intents framework (iOS 16+)
//

import AppIntents
import SwiftData

// MARK: - App Shortcuts Provider

struct W8TrackrShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogWeightIntent(),
            phrases: [
                // English
                "Log my weight in \(.applicationName)",
                "Add weight to \(.applicationName)",
                "Record my weight in \(.applicationName)",
                // Spanish
                "Registrar mi peso en \(.applicationName)",
                "Agregar peso en \(.applicationName)",
                "Anotar mi peso en \(.applicationName)",
                // Chinese (Simplified)
                "在\(.applicationName)记录我的体重",
                "添加体重到\(.applicationName)",
                "用\(.applicationName)记录体重",
                // French
                "Enregistrer mon poids dans \(.applicationName)",
                "Ajouter mon poids dans \(.applicationName)",
                "Noter mon poids dans \(.applicationName)",
                // German
                "Mein Gewicht in \(.applicationName) protokollieren",
                "Gewicht zu \(.applicationName) hinzufügen",
                "Mein Gewicht in \(.applicationName) aufzeichnen",
                // Japanese
                "体重を\(.applicationName)に記録",
                "\(.applicationName)で体重を記録",
                "\(.applicationName)に体重を追加",
                // Portuguese (Brazil)
                "Registrar meu peso no \(.applicationName)",
                "Adicionar peso no \(.applicationName)",
                "Anotar meu peso no \(.applicationName)",
                // Italian
                "Registra il mio peso in \(.applicationName)",
                "Aggiungi peso a \(.applicationName)",
                "Annota il mio peso in \(.applicationName)",
                // Korean
                "내 체중을 \(.applicationName)에 기록",
                "\(.applicationName)에 체중 추가",
                "\(.applicationName)에서 체중 기록",
                // Russian
                "Записать мой вес в \(.applicationName)",
                "Добавить вес в \(.applicationName)",
                "Записать вес в \(.applicationName)"
            ],
            shortTitle: "Log Weight",
            systemImageName: "scalemass"
        )

        AppShortcut(
            intent: GetWeightTrendIntent(),
            phrases: [
                // English
                "What's my weight trend in \(.applicationName)",
                "How is my weight trending in \(.applicationName)",
                "Show weight trend from \(.applicationName)",
                // Spanish
                "Cual es mi tendencia de peso en \(.applicationName)",
                "Como va mi peso en \(.applicationName)",
                "Mostrar tendencia de peso de \(.applicationName)",
                // Chinese (Simplified)
                "我在\(.applicationName)的体重趋势是什么",
                "\(.applicationName)里我的体重趋势",
                "查看\(.applicationName)的体重趋势",
                // French
                "Quelle est ma tendance de poids dans \(.applicationName)",
                "Comment évolue mon poids dans \(.applicationName)",
                "Afficher ma tendance de poids de \(.applicationName)",
                // German
                "Wie ist mein Gewichtstrend in \(.applicationName)",
                "Wie entwickelt sich mein Gewicht in \(.applicationName)",
                "Zeige Gewichtstrend von \(.applicationName)",
                // Japanese
                "\(.applicationName)での体重の傾向は",
                "\(.applicationName)の体重トレンドを見せて",
                "体重の傾向を\(.applicationName)で確認",
                // Portuguese (Brazil)
                "Qual é minha tendência de peso no \(.applicationName)",
                "Como está meu peso no \(.applicationName)",
                "Mostrar tendência de peso do \(.applicationName)",
                // Italian
                "Qual è la mia tendenza di peso in \(.applicationName)",
                "Come sta andando il mio peso in \(.applicationName)",
                "Mostra tendenza peso da \(.applicationName)",
                // Korean
                "내 체중 추세가 \(.applicationName)에서 어때",
                "\(.applicationName)에서 체중 추세 보여줘",
                "\(.applicationName)의 체중 추세 확인",
                // Russian
                "Какова моя тенденция веса в \(.applicationName)",
                "Как идёт мой вес в \(.applicationName)",
                "Показать тенденцию веса из \(.applicationName)"
            ],
            shortTitle: "Weight Trend",
            systemImageName: "chart.line.uptrend.xyaxis"
        )

        AppShortcut(
            intent: GetWeightLossIntent(),
            phrases: [
                // English
                "How much have I lost in \(.applicationName)",
                "What's my weight change in \(.applicationName)",
                "How much weight have I lost in \(.applicationName)",
                // Spanish
                "Cuanto peso he perdido en \(.applicationName)",
                "Cual es mi cambio de peso en \(.applicationName)",
                "Cuanto he bajado en \(.applicationName)",
                // Chinese (Simplified)
                "我在\(.applicationName)减了多少",
                "\(.applicationName)里我的体重变化是多少",
                "用\(.applicationName)查看我减了多少",
                // French
                "Combien ai-je perdu dans \(.applicationName)",
                "Quel est mon changement de poids dans \(.applicationName)",
                "Combien de poids ai-je perdu dans \(.applicationName)",
                // German
                "Wie viel habe ich in \(.applicationName) abgenommen",
                "Was ist meine Gewichtsveränderung in \(.applicationName)",
                "Wie viel Gewicht habe ich in \(.applicationName) verloren",
                // Japanese
                "\(.applicationName)でどのくらい痩せた",
                "\(.applicationName)での体重変化は",
                "どのくらい体重が減ったか\(.applicationName)で確認",
                // Portuguese (Brazil)
                "Quanto eu perdi no \(.applicationName)",
                "Qual é minha mudança de peso no \(.applicationName)",
                "Quanto peso eu perdi no \(.applicationName)",
                // Italian
                "Quanto ho perso in \(.applicationName)",
                "Qual è il mio cambiamento di peso in \(.applicationName)",
                "Quanto peso ho perso in \(.applicationName)",
                // Korean
                "\(.applicationName)에서 얼마나 뺐어",
                "\(.applicationName)에서 체중 변화가 얼마야",
                "\(.applicationName)에서 얼마나 살이 빠졌어",
                // Russian
                "Сколько я сбросил в \(.applicationName)",
                "Каково изменение моего веса в \(.applicationName)",
                "Сколько веса я потерял в \(.applicationName)"
            ],
            shortTitle: "Weight Change",
            systemImageName: "arrow.down.right"
        )
    }
}

// MARK: - Log Weight Intent

struct LogWeightIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Weight"
    static let description = IntentDescription("Opens W8Trackr to log your current weight")

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // The app will open due to openAppWhenRun = true
        // We return a dialog to provide voice feedback
        return .result(dialog: "Opening W8Trackr to log your weight")
    }
}

// MARK: - Get Weight Trend Intent

struct GetWeightTrendIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Weight Trend"
    static let description = IntentDescription("Reports your recent weight trend")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: WeightEntry.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let entries = try context.fetch(descriptor)

        guard entries.count >= 2 else {
            return .result(dialog: "I need at least 2 weight entries to calculate a trend. Keep logging!")
        }

        // Get entries from the last 7 days
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEntries = entries.filter { $0.date >= sevenDaysAgo }

        let entriesToAnalyze = recentEntries.count >= 2 ? recentEntries : Array(entries.prefix(7))

        guard let newest = entriesToAnalyze.first,
              let oldest = entriesToAnalyze.last else {
            return .result(dialog: "Unable to calculate trend")
        }

        // Use preferred unit from UserDefaults
        let preferredUnitString = UserDefaults.standard.string(forKey: "preferredWeightUnit") ?? "lb"
        let unit = WeightUnit(rawValue: preferredUnitString) ?? .lb

        let newestWeight = newest.weightValue(in: unit)
        let oldestWeight = oldest.weightValue(in: unit)
        let change = newestWeight - oldestWeight

        let trendDescription: String
        let changeAmount = abs(change).formatted(.number.precision(.fractionLength(1)))

        if abs(change) < 0.5 {
            trendDescription = "Your weight has been stable at \(newestWeight.formatted(.number.precision(.fractionLength(1)))) \(unit.rawValue)"
        } else if change < 0 {
            trendDescription = "You're down \(changeAmount) \(unit.rawValue)! Your current weight is \(newestWeight.formatted(.number.precision(.fractionLength(1)))) \(unit.rawValue)"
        } else {
            trendDescription = "You're up \(changeAmount) \(unit.rawValue). Your current weight is \(newestWeight.formatted(.number.precision(.fractionLength(1)))) \(unit.rawValue)"
        }

        return .result(dialog: "\(trendDescription)")
    }
}

// MARK: - Get Weight Loss Intent

struct GetWeightLossIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Weight Change"
    static let description = IntentDescription("Reports your total weight change since you started tracking")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: WeightEntry.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let entries = try context.fetch(descriptor)

        guard let firstEntry = entries.first,
              let lastEntry = entries.last,
              entries.count >= 2 else {
            return .result(dialog: "I need at least 2 weight entries to calculate your progress. Keep logging!")
        }

        // Use preferred unit from UserDefaults
        let preferredUnitString = UserDefaults.standard.string(forKey: "preferredWeightUnit") ?? "lb"
        let unit = WeightUnit(rawValue: preferredUnitString) ?? .lb

        let startWeight = firstEntry.weightValue(in: unit)
        let currentWeight = lastEntry.weightValue(in: unit)
        let totalChange = currentWeight - startWeight

        let changeAmount = abs(totalChange).formatted(.number.precision(.fractionLength(1)))
        let startFormatted = startWeight.formatted(.number.precision(.fractionLength(1)))
        let currentFormatted = currentWeight.formatted(.number.precision(.fractionLength(1)))

        let timeSpan = Calendar.current.dateComponents([.day], from: firstEntry.date, to: lastEntry.date)
        let days = timeSpan.day ?? 0
        let timeDescription = days == 1 ? "1 day" : "\(days) days"

        let message: String
        if abs(totalChange) < 0.5 {
            message = "Your weight has stayed steady at around \(currentFormatted) \(unit.rawValue) over \(timeDescription)"
        } else if totalChange < 0 {
            message = "Great progress! You've lost \(changeAmount) \(unit.rawValue) over \(timeDescription). You started at \(startFormatted) and you're now at \(currentFormatted) \(unit.rawValue)"
        } else {
            message = "You've gained \(changeAmount) \(unit.rawValue) over \(timeDescription). You started at \(startFormatted) and you're now at \(currentFormatted) \(unit.rawValue)"
        }

        return .result(dialog: "\(message)")
    }
}
