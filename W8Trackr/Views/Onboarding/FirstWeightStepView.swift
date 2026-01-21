//
//  FirstWeightStepView.swift
//  W8Trackr
//
//  Initial weight entry screen for onboarding
//

import SwiftUI

struct FirstWeightStepView: View {
    var weightUnit: WeightUnit
    @Binding var enteredWeight: Double
    @Binding var isValid: Bool

    var onContinue: () -> Void

    @State private var showContent = false
    @State private var localWeightText: String = ""
    @FocusState private var isWeightFieldFocused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var weightFontSize: CGFloat = 64

    private var enteredValue: Double? {
        Double(localWeightText)
    }

    private var isValidWeight: Bool {
        guard let value = enteredValue else { return false }
        return weightUnit.isValidWeight(value)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 40)

                    // Header
                    VStack(spacing: 12) {
                        Text("Your Current Weight")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Let's log your starting point")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1.0 : 0.0)

                    Spacer()
                        .frame(height: 20)

                    // Weight input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        VStack(spacing: 4) {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                TextField("", text: $localWeightText)
                                    .font(.system(size: weightFontSize, weight: .medium))
                                    .keyboardType(.decimalPad)
                                    .fixedSize()
                                    .multilineTextAlignment(.trailing)
                                    .foregroundStyle(localWeightText.isEmpty || isValidWeight ? AppColors.primaryDark : AppColors.primaryDark.opacity(0.5))
                                    .focused($isWeightFieldFocused)
                                    .frame(minWidth: 80)
                                    .padding(.trailing, 4)
                                    .toolbar {
                                        ToolbarItemGroup(placement: .keyboard) {
                                            Spacer()
                                            Button("Done") {
                                                isWeightFieldFocused = false
                                            }
                                        }
                                    }
                                    .onChange(of: localWeightText) { _, newValue in
                                        // Filter to only allow numbers and decimal point
                                        var filtered = newValue.filter { $0.isNumber || $0 == "." }
                                        // Only allow one decimal point
                                        let parts = filtered.split(separator: ".", omittingEmptySubsequences: false)
                                        if parts.count > 2 {
                                            filtered = String(parts[0]) + "." + String(parts[1])
                                        }
                                        // Limit to 4 digits (not counting decimal point)
                                        let digitCount = filtered.filter { $0.isNumber }.count
                                        if digitCount > 4 {
                                            var digits = 0
                                            filtered = String(filtered.prefix { char in
                                                if char.isNumber {
                                                    digits += 1
                                                    return digits <= 4
                                                }
                                                return true
                                            })
                                        }
                                        if filtered != newValue {
                                            localWeightText = filtered
                                        }
                                    }

                                Text(weightUnit.displayName)
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            }

                            // Underline to indicate tappable area
                            Rectangle()
                                .fill(AppColors.primary.opacity(0.4))
                                .frame(height: 2)
                        }
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal)
                    .scaleEffect(showContent ? 1.0 : 0.95)
                    .opacity(showContent ? 1.0 : 0.0)

                    // Bottom padding to account for button
                    Spacer()
                        .frame(height: 100)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            // Continue button - fixed at bottom, ignores keyboard
            Button {
                if let value = enteredValue {
                    enteredWeight = value
                }
                onContinue()
            } label: {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidWeight ? AppColors.primary : AppColors.primary.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!isValidWeight)
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            .opacity(showContent ? 1.0 : 0.0)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // Set initial validation state (onChange only fires on changes)
            isValid = isValidWeight
            animateEntrance()
            // Auto-focus after view appears (delay for TabView transition)
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                isWeightFieldFocused = true
            }
        }
        .onChange(of: localWeightText) {
            isValid = isValidWeight
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            showContent = true
        }
    }
}

#Preview {
    FirstWeightStepView(weightUnit: .lb, enteredWeight: .constant(180.0), isValid: .constant(false), onContinue: {})
}
