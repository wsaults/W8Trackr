//
//  ContentView.swift
//  W8Trackr
//
//  Created by Will Saults on 4/28/25.
//

import Charts
import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @Query(
        sort: [SortDescriptor(\WeightEntry.date, order: .reverse)]
    ) private var entries: [WeightEntry]
    
    @State private var showAddWeightView = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack {
                    if entries.isEmpty {
                        ContentUnavailableView("Start Tracking!", systemImage: "person.badge.plus", description: Text("Tap the + button to track your weight"))
                    } else {
                        CurrentWeightView(weight: entries.first?.weightValue ?? 0)
                        
                        ScrollView {
                            VStack(spacing: .zero) {
                                ChartSectionView(entries: entries)
                                HistorySectionView(entries: entries)
                            }
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
            .navigationTitle("Weight Tracker")
            .sheet(isPresented: $showAddWeightView) {
                AddWeightView()
            }
        }
    }
}

@available(iOS 18, macOS 15, *)
#Preview(traits: .modifier(EntriesPreview())) {
    @Previewable @Query var entries: [WeightEntry]
    
    ContentView()
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
