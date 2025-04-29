//
//  SummaryView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Charts
import SwiftData
import SwiftUI

struct SummaryView: View {
    @State private var showAddWeightView = false
    
    var entries: [WeightEntry]
    var preferredWeightUnit: WeightUnit
    var goalWeight: Double
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack {
                    if entries.isEmpty {
                        ContentUnavailableView(
                            "Start Tracking!",
                            systemImage: "person.badge.plus",
                            description: Text("Tap the + button to track your weight")
                        )
                    } else {
                        if let entry = entries.first {
                            CurrentWeightView(
                                weight: entry.weightValue(in: preferredWeightUnit),
                                weightUnit: preferredWeightUnit
                            )
                        }
                        
                        ScrollView {
                            ChartSectionView(entries: entries, goalWeight: goalWeight, weightUnit: preferredWeightUnit)
                        }
                    }
                }
                
                Button {
                    showAddWeightView.toggle()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .fontWeight(.bold)
                        .padding()
                        .background(.blue)
                        .clipShape(.circle)
                }
            }
            .background(.gray.opacity(0.1))
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAddWeightView) {
                AddWeightView(entries: entries, weightUnit: preferredWeightUnit)
            }
        }
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(EntriesPreview())) {
    @Previewable @Query var entries: [WeightEntry]
    
    SummaryView(entries: WeightEntry.shortSampleData, preferredWeightUnit: .lb, goalWeight: 160)
}

struct EntriesPreview: PreviewModifier {
    static func makeSharedContext() async throws -> ModelContainer {
        let container = try ModelContainer(for: WeightEntry.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let examples = WeightEntry.sampleData
        examples.forEach { example in
            container.mainContext.insert(example)
        }
        return container
    }
    
    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}
