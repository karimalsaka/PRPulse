import SwiftUI

struct OnboardingStepView<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        AppCard {
            VStack(spacing: 24) {
                // Title and Subtitle
                headerText

                // Content
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(32)
        }
    }

    // MARK: - Header Text

    private var headerText: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Preview

struct OnboardingStepView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingStepView(
            title: "Welcome to blnk",
            subtitle: "Monitor your GitHub pull requests from your menu bar"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("blnk helps you stay on top of your pull requests with:")
                    .font(.subheadline)

                BulletPointView(text: "Real-time status updates")
                BulletPointView(text: "CI/CD check monitoring")
                BulletPointView(text: "Review state tracking")
                BulletPointView(text: "Recent comment notifications")
            }
        }
        .frame(width: 600)
        .padding()
        .preferredColorScheme(.dark)
    }
}

// MARK: - Bullet Point Helper

struct BulletPointView: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Text(text)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}
