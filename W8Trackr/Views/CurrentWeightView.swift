import SwiftUI

struct CurrentWeightView: View {
    let weight: Double
    let weightUnit: WeightUnit
    
    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(weight, format: .number.precision(.fractionLength(1)))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(weightUnit.rawValue)
            }
            Text("Current Weight")
                .font(.footnote)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .padding()
    }
}

#Preview {
    CurrentWeightView(weight: 175, weightUnit: .lb)
}

