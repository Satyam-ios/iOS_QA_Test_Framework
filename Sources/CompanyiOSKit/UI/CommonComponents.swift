import SwiftUI

/// Accessible loading spinner with informative text.
public struct LoadingIndicatorView: View {
    public let message: String

    public init(message: String = "Loading...") {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

/// Accessible empty state view for lists or dashboards.
public struct EmptyStateView: View {
    public let title: String
    public let message: String
    public let systemImageName: String
    public let actionTitle: String?
    public let action: (() -> Void)?

    public init(
        title: String,
        message: String,
        systemImageName: String = "tray",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImageName = systemImageName
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImageName)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding(24)
        .accessibilityElement(children: .contain)
    }
}

/// Accessible banner displaying error messages and optional retry.
public struct ErrorBannerView: View {
    public let error: UserFacingError
    public let onRetry: (() -> Void)?

    public init(error: UserFacingError, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(error.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(error.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if error.isRetryable, let onRetry = onRetry {
                    Button(action: onRetry) {
                        Text(error.actionTitle ?? "Retry")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 4)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(error.title). \(error.message)")
    }
}

/// Standard accessible action button with loading state.
public struct PrimaryActionButton: View {
    public let title: String
    public let isLoading: Bool
    public let action: () -> Void

    public init(title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: {
            if !isLoading { action() }
        }) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.trailing, 8)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isLoading ? [.updatesFrequently] : [])
    }
}
