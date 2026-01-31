import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    let onSave: () -> Void
    @AppStorage(NotificationPreferences.Keys.notifyComments) private var notifyComments = false
    @AppStorage(NotificationPreferences.Keys.notifyReviews) private var notifyReviews = false
    @State private var notificationStatus: String = "Unknown"
    @State private var notificationStyle: String = "Unknown"

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            header

                            AppCard {
                                VStack(alignment: .leading, spacing: 20) {
                                    tokenSection
                                    notificationsSection

                                    if let result = viewModel.validationResult {
                                        PermissionChecklistView(validationResult: result)
                                            .id("validation-results")
                                    }
                                }
                                .padding(24)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                    }
                    .scrollIndicators(.hidden)
                    .onChange(of: viewModel.validationResult != nil) { isPresent in
                        guard isPresent else { return }
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("validation-results", anchor: .top)
                        }
                    }
                }

                Divider()

                footer
                    .padding(20)
            }
        }
        .frame(width: 600, height: 700)
        .background(AppTheme.canvas)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Token Settings")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                Text("Replace and validate your GitHub token")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.stroke.opacity(0.6), lineWidth: 1)
                )
        )
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("Remove Token", role: .destructive) {
                viewModel.removeToken()
            }
            .buttonStyle(AppSoftButtonStyle(tint: AppTheme.danger))

            Spacer()

            Button("Save") {
                if viewModel.saveToken() {
                    onSave()
                }
            }
            .buttonStyle(AppPrimaryButtonStrongStyle())
            .opacity(viewModel.tokenInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)
            .disabled(viewModel.tokenInput.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var tokenSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Replace Token")
                    .font(.headline)
                Spacer()
                Button("Paste Saved") {
                    viewModel.tokenInput = TokenManager.shared.getToken() ?? ""
                }
                .buttonStyle(AppSoftButtonStyle(tint: .secondary))
            }

            TokenInputView(
                tokenInput: $viewModel.tokenInput,
                isValidating: viewModel.isValidating,
                onValidate: viewModel.validateToken
            )

            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.caption)
                    .foregroundColor(AppTheme.info)
                Text("Validate to preview permissions before saving.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.headline)

            Toggle("New comments", isOn: $notifyComments)
                .toggleStyle(.switch)
                .onChange(of: notifyComments) { newValue in
                    if newValue {
                        NotificationManager.shared.requestAuthorizationIfNeeded()
                        refreshNotificationStatus()
                    }
                }

            Toggle("New reviews", isOn: $notifyReviews)
                .toggleStyle(.switch)
                .onChange(of: notifyReviews) { newValue in
                    if newValue {
                        NotificationManager.shared.requestAuthorizationIfNeeded()
                        refreshNotificationStatus()
                    }
                }

            HStack(spacing: 6) {
                Text("Status: \(notificationStatus) · Style: \(notificationStyle)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button("Open Notification Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
            }

            Text("Only non-bot, non-self activity is notified.")
                .font(.caption)
                .foregroundColor(.secondary)

#if DEBUG
            Button("Send Test Notification (3s)") {
                NotificationManager.shared.requestAuthorizationIfNeeded()
                NotificationManager.shared.scheduleTestNotification()
                refreshNotificationStatus()
            }
            .buttonStyle(AppSoftButtonStyle(tint: AppTheme.info))
#endif
        }
        .onAppear {
            refreshNotificationStatus()
        }
    }

    private func refreshNotificationStatus() {
        NotificationManager.shared.fetchNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized: notificationStatus = "Authorized"
                case .denied: notificationStatus = "Denied"
                case .notDetermined: notificationStatus = "Not Determined"
                case .provisional: notificationStatus = "Provisional"
                case .ephemeral: notificationStatus = "Ephemeral"
                @unknown default: notificationStatus = "Unknown"
                }

                switch settings.alertStyle {
                case .none: notificationStyle = "None"
                case .banner: notificationStyle = "Banner"
                case .alert: notificationStyle = "Alert"
                @unknown default: notificationStyle = "Unknown"
                }
            }
        }
    }
}

#Preview("Settings") {
    SettingsView(onSave: {})
        .preferredColorScheme(.dark)
}
