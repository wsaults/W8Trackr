import SwiftUI
import SwiftData

struct LogbookView: View {
    var entries: [WeightEntry]
    var preferredWeightUnit: WeightUnit
    var goalWeight: Double
    @State private var showingAddWeight = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Weight Entries",
                        systemImage: "book.closed",
                        description: Text("Add your first weight entry to start tracking your progress")
                    )
                } else {
                    HistorySectionView(entries: entries, weightUnit: preferredWeightUnit)
                }
            }
            .navigationTitle("Logbook")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddWeight = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddWeight) {
                AddWeightView(entries: entries, weightUnit: preferredWeightUnit)
            }
        }
    }
}

#Preview {
    LogbookView(entries: WeightEntry.shortSampleData, preferredWeightUnit: .lb, goalWeight: 160)
}
