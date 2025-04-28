import SwiftUI

struct HistorySectionView: View {
    @Environment(\.modelContext) private var modelContext
    let entries: [WeightEntry]
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm a"
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
                            Text(entry.weightValue, format: .number.precision(.fractionLength(1)))
                                .fontWeight(.bold)
                            Text(entry.weightUnit)
                        }
                    }
                    .padding(.vertical, 8)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                modelContext.delete(entry)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { _ in
                    
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
    HistorySectionView(entries: WeightEntry.sortedSampleData)
}
