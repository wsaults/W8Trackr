import SwiftUI

struct CurrentWeightView: View {
    let weight: Double
    let weightUnit: String
    
    var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(weight, format: .number.precision(.fractionLength(1)))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(weightUnit)
            }
            Text("Current Weight")
                .font(.footnote)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white)
        .cornerRadius(10)
        .padding()
    }
}

#Preview {
    CurrentWeightView(weight: 175, weightUnit: "lb")
}

