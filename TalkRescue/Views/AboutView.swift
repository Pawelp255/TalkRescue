import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(L10n.About.privacySection) {
                    Text(L10n.About.privacyBody)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(L10n.About.appSection) {
                    LabeledContent(L10n.About.nameLabel, value: "TalkRescue")
                    LabeledContent(L10n.About.versionLabel, value: appVersion)
                    LabeledContent(L10n.About.buildLabel, value: appBuild)
                }

                Section(L10n.About.quickLaunchSection) {
                    Text(L10n.About.quickLaunchBody)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Section(L10n.About.translationSection) {
                    Text(L10n.About.translationBody)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .navigationTitle(L10n.About.title)
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
