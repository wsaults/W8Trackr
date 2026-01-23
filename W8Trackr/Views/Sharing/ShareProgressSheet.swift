//
//  ShareProgressSheet.swift
//  W8Trackr
//
//  Sheet for previewing and sharing progress images with privacy controls.
//

import SwiftUI

/// Sheet that displays a preview of the shareable progress image with privacy controls.
struct ShareProgressSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("shareHideExactWeights") private var hideExactWeights = true

    let progressPercentage: Double
    let weightChange: Double
    let duration: String
    let unit: WeightUnit

    @State private var generatedImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Image preview
                if let generatedImage {
                    Image(uiImage: generatedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(.rect(cornerRadius: 12))
                        .padding()
                }

                // Privacy toggle
                Toggle("Hide exact weights", isOn: $hideExactWeights)
                    .padding(.horizontal)
                    .onChange(of: hideExactWeights) { _, _ in
                        regenerateImage()
                    }

                // Share button
                if let generatedImage {
                    ShareLink(
                        item: ShareableProgressImage(image: generatedImage, title: "My W8Trackr Progress"),
                        preview: SharePreview("My W8Trackr Progress", image: Image(uiImage: generatedImage))
                    ) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Share Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                regenerateImage()
            }
        }
    }

    private func regenerateImage() {
        generatedImage = ProgressImageGenerator.generateProgressImage(
            progressPercentage: progressPercentage,
            weightChange: weightChange,
            duration: duration,
            showWeights: !hideExactWeights,
            unit: unit
        )
    }
}

#Preview {
    ShareProgressSheet(
        progressPercentage: 65,
        weightChange: -12.5,
        duration: "3 months",
        unit: .lb
    )
}
