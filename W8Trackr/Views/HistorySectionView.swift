import SwiftUI

struct HistorySectionView: View {
    @Environment(\.modelContext) private var modelContext
    let entries: [WeightEntry]
    let weightUnit: WeightUnit
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter
    }()
    
    var body: some View {
        Section {
            List {
                ForEach(entries) { entry in
                    HStack {
                        Text(entry.date, formatter: Self.dateFormatter)
                        Spacer()
                        HStack(spacing: 4) {
                            Text(
                                entry.weightValue(in: weightUnit),
                                format: .number.precision(.fractionLength(1))
                            )
                            .fontWeight(.bold)
                            
                            Text(weightUnit.rawValue)
                        }
                    }
                    .padding(.vertical, 8)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                modelContext.delete(entry)
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        } header: {
            HStack {
                Text("History")
                    .font(.title2)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    HistorySectionView(entries: WeightEntry.sortedSampleData, weightUnit: .lb)
}
