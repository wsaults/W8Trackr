//
//  AboutView.swift
//  W8Trackr
//
//  Created by Will Saults on 1/20/26.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            List {
                appHeaderSection
                legalSection
                creditsSection
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Sections

    private var appHeaderSection: some View {
        Section {
            VStack(spacing: 12) {
                if let icon = UIImage(named: "AppIcon") {
                    Image(uiImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(.rect(cornerRadius: 18))
                        .padding(.top, 8)
                }

                Text("W8Trackr")
                    .font(.title2)
                    .bold()

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Simple weight tracking\nwith smart insights")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        }
    }

    private var linksSection: some View {
        Section {
            Link(destination: URL(string: "mailto:support@w8trackr.app")!) {
                Label("Send Feedback", systemImage: "envelope")
            }

            Button {
                requestAppStoreReview()
            } label: {
                Label("Rate on App Store", systemImage: "star")
            }

            Link(destination: URL(string: "https://twitter.com/w8trackrapp")!) {
                Label("Follow on X", systemImage: "at")
            }
        } header: {
            Text("Connect")
        }
    }

    private var legalSection: some View {
        Section {
            Link(destination: URL(string: "https://saults.io/w8trackr-privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }

            Link(destination: URL(string: "https://saults.io/w8trackr-support")!) {
                Label("Support", systemImage: "questionmark.circle")
            }
        } header: {
            Text("Legal")
        }
    }

    private var creditsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Made with 🤖 by Will Saults")
                    .font(.subheadline)
                Text("© 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Credits")
        } footer: {
            Text("Thank you for using W8Trackr!")
        }
    }

    // MARK: - Actions

    private func requestAppStoreReview() {
        // App Store ID placeholder - replace with actual ID after release
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id123456789?action=write-review") else {
            return
        }
        UIApplication.shared.open(url)
    }
}

// MARK: - Previews

#Preview {
    AboutView()
}
