import Charts
import SwiftUI

struct ChartSectionView: View {
    let entries: [WeightEntry]
    let goalWeight: Double
    let weightUnit: String
    
    var body: some View {
        Section {
            SingleLineLollipop(entries: entries, goalWeight: goalWeight, weightUnit: weightUnit)
                .frame(height: 200)
                .padding()
                .background(.white)
                .cornerRadius(10)
                .padding()
        } header: {
            HStack {
                Text("Chart")
                    .font(.title2)
                Spacer()
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ChartSectionView(entries: WeightEntry.sortedSampleData, goalWeight: 160.0, weightUnit: "lb")
}
