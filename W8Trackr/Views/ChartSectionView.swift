import Charts
import SwiftUI

struct ChartSectionView: View {
    let entries: [WeightEntry]
    
    var body: some View {
        Section {
            SingleLineLollipop(entries: entries)
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
    ChartSectionView(entries: WeightEntry.sortedSampleData)
}
