import SwiftUI

struct CurrentWeightView: View {
    let weight: Double
    
    var body: some View {
        VStack {
            Text(weight, format: .number.precision(.fractionLength(1)))
                .font(.largeTitle)
                .fontWeight(.bold)
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