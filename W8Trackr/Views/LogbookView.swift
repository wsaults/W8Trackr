import SwiftUI
import SwiftData

struct LogbookView: View {
    var entries: [WeightEntry]
    var preferredWeightUnit: WeightUnit
    var goalWeight: Double
    
    var body: some View {
        NavigationStack {
//            List(entries) { entry in
//                VStack(alignment: .leading) {
//                    Text("\(entry.weight, specifier: "%.1f") lbs")
//                        .font(.headline)
//                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
//                        .font(.caption)
//                        .foregroundStyle(.secondary)
//                }
//            }
            VStack {
                HistorySectionView(entries: entries, weightUnit: preferredWeightUnit)
            }
            .navigationTitle("Logbook")
        }
    }
}

#Preview {
    LogbookView(entries: WeightEntry.shortSampleData, preferredWeightUnit: .lb, goalWeight: 160)
}
