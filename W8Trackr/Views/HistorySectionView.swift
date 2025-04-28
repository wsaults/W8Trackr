import SwiftUI

struct HistorySectionView: View {
    let entries: [WeightEntry]
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    var body: some View {
        Section {
            VStack {
                ForEach(entries) { entry in
                    VStack {
                        HStack {
                            Text(entry.date, formatter: Self.dateFormatter)
                            Spacer()
                            HStack(spacing: 4) {
                                Text(entry.weightValue, format: .number.precision(.fractionLength(1)))
                                    .fontWeight(.bold)
                                Text(entry.weightUnit)
                            }
                        }
                        
                        Divider()
                    }
                }
            }
            .padding()
            .background(.white)
            .cornerRadius(10)
            .padding()
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