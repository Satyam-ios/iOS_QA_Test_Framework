import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif

/// Central registry managing discovered and developer-registered application screens and journeys.
public final class ScreenRegistry: @unchecked Sendable {
    public static let shared = ScreenRegistry()

    private let lock = NSLock()
    private var screens: [String: ScreenDefinition] = [:]
    private var journeys: [String: UserJourney] = [:]

    private init() {
        // Starts clean by default: only real screens registered or dynamically observed appear.
    }

    /// Registers a screen definition into the test discovery engine.
    public func register(_ screen: ScreenDefinition) {
        lock.lock()
        defer { lock.unlock() }
        screens[screen.id] = screen
    }

    /// Convenience registration of a screen with basic parameters.
    public func register(
        id: String,
        name: String,
        route: String,
        elements: [UIElementDescriptor] = [],
        apiDependencies: [String] = [],
        supportedActions: [UserActionDescriptor] = [],
        sourceFile: String? = nil,
        viewClassName: String? = nil
    ) {
        let screen = ScreenDefinition(
            id: id,
            name: name,
            route: route,
            elements: elements,
            apiDependencies: apiDependencies,
            availableStates: [.normal, .loading, .empty, .error(message: "Failed to load")],
            supportedActions: supportedActions,
            sourceFile: sourceFile,
            viewClassName: viewClassName
        )
        register(screen)
    }

    /// Registers a multi-screen user journey.
    public func registerJourney(_ journey: UserJourney) {
        lock.lock()
        defer { lock.unlock() }
        journeys[journey.id] = journey
    }

    /// Records a screen observed dynamically at runtime.
    public func recordRuntimeScreen(
        name: String,
        route: String,
        viewClass: String? = nil,
        elements: [UIElementDescriptor] = []
    ) {
        lock.lock()
        defer { lock.unlock() }

        let screenId = "runtime_\(route.replacingOccurrences(of: "/", with: "_").trimmingCharacters(in: CharacterSet(charactersIn: "_")))"
        if var existing = screens[screenId] {
            existing.discoverySource = .runtimeObservation
            if let vc = viewClass { existing.viewClassName = vc }
            if !elements.isEmpty { existing.elements = elements }
            screens[screenId] = existing
        } else {
            let screen = ScreenDefinition(
                id: screenId,
                name: name,
                route: route,
                elements: elements,
                discoverySource: .runtimeObservation,
                viewClassName: viewClass
            )
            screens[screenId] = screen
        }
    }

    /// Merges screens discovered via static source code analysis.
    public func recordDiscoveredScreen(fromStaticAnalysis screen: ScreenDefinition) {
        lock.lock()
        defer { lock.unlock() }
        screens[screen.id] = screen
    }

    /// Bulk registers screens discovered via static analysis.
    public func registerDiscoveredScreens(_ discovered: [ScreenDefinition]) {
        lock.lock()
        defer { lock.unlock() }
        for screen in discovered {
            screens[screen.id] = screen
        }
    }

    /// Updates aggregated test execution metrics for a specific screen.
    public func updateTestMetrics(forScreenId id: String, metrics: ScreenTestMetrics) {
        lock.lock()
        defer { lock.unlock() }
        guard var screen = screens[id] else { return }
        screen.testMetrics = metrics
        screens[id] = screen
    }

    /// Links a defect identifier to a screen record.
    public func linkDefect(id defectId: String, toScreenId screenId: String) {
        lock.lock()
        defer { lock.unlock() }
        guard var screen = screens[screenId] else { return }
        if !screen.linkedDefectIds.contains(defectId) {
            screen.linkedDefectIds.append(defectId)
        }
        screens[screenId] = screen
    }

    public var allScreens: [ScreenDefinition] {
        lock.lock()
        defer { lock.unlock() }
        #if canImport(UIKit) && !os(watchOS)
        if screens.isEmpty && Thread.isMainThread {
            lock.unlock()
            discoverRunningScreens()
            lock.lock()
        }
        #endif
        return Array(screens.values).sorted { $0.name < $1.name }
    }

    #if canImport(UIKit) && !os(watchOS)
    /// Discovers screens dynamically from the live UIKit window and view controller hierarchy.
    @MainActor
    public func discoverRunningScreens() {
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }),
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = keyWindow.rootViewController else {
            return
        }

        lock.lock()
        defer { lock.unlock() }
        discoverFromViewController(rootVC)
    }

    @MainActor
    private func discoverFromViewController(_ vc: UIViewController) {
        let className = String(describing: type(of: vc))
        let ignoredSubstrings = ["UIHostingController", "UIInputWindowController", "UINavigationController", "UITabBarController", "UIAlertController"]
        let isIgnored = ignoredSubstrings.contains { className.contains($0) }

        if !isIgnored {
            let screenName = formatScreenName(from: className)
            let route = "/" + className.lowercased()
                .replacingOccurrences(of: "viewcontroller", with: "")
                .replacingOccurrences(of: "vc", with: "")
            let screenId = "screen_\(className.lowercased())"

            if screens[screenId] == nil {
                let elements = inspectViewElements(in: vc.view)
                let screen = ScreenDefinition(
                    id: screenId,
                    name: screenName,
                    route: route.isEmpty ? "/root" : route,
                    elements: elements,
                    availableStates: [.normal, .loading, .error(message: "Failed to load")],
                    discoverySource: .runtimeObservation,
                    viewClassName: className
                )
                screens[screenId] = screen
            }
        }

        for child in vc.children {
            discoverFromViewController(child)
        }

        if let presented = vc.presentedViewController {
            discoverFromViewController(presented)
        }
    }

    private func formatScreenName(from className: String) -> String {
        var clean = className
        if clean.hasSuffix("ViewController") {
            clean = String(clean.dropLast("ViewController".count))
        } else if clean.hasSuffix("VC") {
            clean = String(clean.dropLast("VC".count))
        }

        var result = ""
        for char in clean {
            if char.isUppercase && !result.isEmpty {
                result.append(" ")
            }
            result.append(char)
        }
        return result.isEmpty ? className : result
    }

    @MainActor
    private func inspectViewElements(in view: UIView) -> [UIElementDescriptor] {
        var elements: [UIElementDescriptor] = []
        var queue: [UIView] = [view]

        while !queue.isEmpty && elements.count < 40 {
            let current = queue.removeFirst()
            var type: UIElementType?
            if current is UIButton {
                type = .button
            } else if current is UITextField {
                type = .textField
            } else if current is UISwitch {
                type = .toggle
            } else if current is UITableView || current is UICollectionView {
                type = .list
            } else if current is UILabel {
                type = .label
            }

            if let elType = type {
                let id = current.accessibilityIdentifier ?? "\(elType.rawValue)_\(elements.count + 1)"
                let text = (current as? UILabel)?.text ?? (current as? UIButton)?.currentTitle ?? (current as? UITextField)?.text
                let label = current.accessibilityLabel ?? text

                var isTruncated = false
                if let lbl = current as? UILabel, let txt = lbl.text {
                    let hasEllipsis = txt.hasSuffix("...") || txt.hasSuffix("…")
                    let targetSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: lbl.bounds.height > 0 ? lbl.bounds.height : 30)
                    let requiredWidth = lbl.sizeThatFits(targetSize).width
                    let isClipped = lbl.bounds.width > 0 && requiredWidth > lbl.bounds.width + 1.0
                    isTruncated = hasEllipsis || isClipped
                }

                elements.append(UIElementDescriptor(
                    id: id,
                    type: elType,
                    accessibilityIdentifier: current.accessibilityIdentifier,
                    accessibilityLabel: label,
                    textContent: text,
                    isTruncated: isTruncated
                ))
            }

            queue.append(contentsOf: current.subviews)
        }

        return elements
    }
    #endif

    public var allJourneys: [UserJourney] {
        lock.lock()
        defer { lock.unlock() }
        return Array(journeys.values).sorted { $0.name < $1.name }
    }

    public func screen(withId id: String) -> ScreenDefinition? {
        lock.lock()
        defer { lock.unlock() }
        return screens[id]
    }

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        screens.removeAll()
        journeys.removeAll()
    }

    /// Explicitly loads sample screens and journeys for test fixtures or demonstration.
    public func seedSampleFixtures() {
        lock.lock()
        defer { lock.unlock() }
        populateDefaultDiscoveredLandscape()
    }

    /// Clears any default sample fixtures so that only real discovered screens from the host app remain.
    public func clearSampleFixtures() {
        lock.lock()
        defer { lock.unlock() }
        let sampleIds = ["screen_login", "screen_home", "screen_profile", "screen_contacts"]
        for sid in sampleIds {
            screens.removeValue(forKey: sid)
        }
        journeys.removeValue(forKey: "journey_standard_flow")
    }

    /// Automatic fallback discovery ensuring zero-config out-of-the-box support for standard iOS journeys.
    private func populateDefaultDiscoveredLandscape() {
        let loginScreen = ScreenDefinition(
            id: "screen_login",
            name: "Login Screen",
            route: "/login",
            elements: [
                UIElementDescriptor(id: "field_email", type: .textField, accessibilityIdentifier: "login_email_field", accessibilityLabel: "Email address"),
                UIElementDescriptor(id: "field_password", type: .secureField, accessibilityIdentifier: "login_password_field", accessibilityLabel: "Password"),
                UIElementDescriptor(id: "btn_submit", type: .button, accessibilityIdentifier: "login_submit_btn", accessibilityLabel: "Log In")
            ],
            apiDependencies: ["/api/v1/auth/login"],
            availableStates: [.normal, .loading, .error(message: "Invalid credentials")],
            supportedActions: [
                UserActionDescriptor(id: "act_login", name: "Submit Login", targetElementId: "btn_submit", targetRoute: "/home")
            ],
            sourceFile: "Sources/Authentication/LoginViewController.swift",
            sourceLine: 35,
            featureModule: "Auth",
            discoverySource: .staticSourceAnalysis,
            testMetrics: ScreenTestMetrics(generatedCount: 4, executedCount: 4, passedCount: 4, failedCount: 0, blockedCount: 0, notExecutedCount: 0),
            viewClassName: "LoginViewController"
        )

        let homeScreen = ScreenDefinition(
            id: "screen_home",
            name: "Home Dashboard",
            route: "/home",
            elements: [
                UIElementDescriptor(id: "btn_profile", type: .button, accessibilityIdentifier: "nav_profile_btn", accessibilityLabel: "Profile"),
                UIElementDescriptor(id: "btn_contacts", type: .button, accessibilityIdentifier: "nav_contacts_btn", accessibilityLabel: "Contacts"),
                UIElementDescriptor(id: "btn_settings", type: .button, accessibilityIdentifier: "nav_settings_btn", accessibilityLabel: "Settings")
            ],
            apiDependencies: ["/api/v1/dashboard"],
            availableStates: [.normal, .loading, .empty],
            supportedActions: [
                UserActionDescriptor(id: "act_goto_profile", name: "Navigate to Profile", targetElementId: "btn_profile", targetRoute: "/profile"),
                UserActionDescriptor(id: "act_goto_contacts", name: "Navigate to Contacts", targetElementId: "btn_contacts", targetRoute: "/contacts")
            ],
            sourceFile: "Sources/Dashboard/HomeDashboardViewController.swift",
            sourceLine: 42,
            featureModule: "Dashboard",
            discoverySource: .staticSourceAnalysis,
            testMetrics: ScreenTestMetrics(generatedCount: 3, executedCount: 3, passedCount: 3, failedCount: 0, blockedCount: 0, notExecutedCount: 0),
            viewClassName: "HomeDashboardViewController"
        )

        let profileScreen = ScreenDefinition(
            id: "screen_profile",
            name: "User Profile",
            route: "/profile",
            elements: [
                UIElementDescriptor(id: "field_display_name", type: .textField, accessibilityIdentifier: "profile_name_field", accessibilityLabel: "Display Name"),
                UIElementDescriptor(id: "btn_save_profile", type: .button, accessibilityIdentifier: "profile_save_btn", accessibilityLabel: "Save Profile")
            ],
            apiDependencies: ["/api/v1/profile/update"],
            availableStates: [.normal, .loading, .error(message: "Update failed")],
            supportedActions: [
                UserActionDescriptor(id: "act_save", name: "Save Profile", targetElementId: "btn_save_profile")
            ],
            sourceFile: "Sources/Profile/UserProfileViewController.swift",
            sourceLine: 28,
            featureModule: "Profile",
            discoverySource: .staticSourceAnalysis,
            testMetrics: ScreenTestMetrics(generatedCount: 2, executedCount: 2, passedCount: 2, failedCount: 0, blockedCount: 0, notExecutedCount: 0),
            viewClassName: "UserProfileViewController"
        )

        let contactsScreen = ScreenDefinition(
            id: "screen_contacts",
            name: "Contacts List",
            route: "/contacts",
            elements: [
                UIElementDescriptor(id: "list_contacts", type: .list, accessibilityIdentifier: "contacts_table", accessibilityLabel: "Contacts list"),
                UIElementDescriptor(id: "btn_add_contact", type: .button, accessibilityIdentifier: "contacts_add_btn", accessibilityLabel: "Add Contact")
            ],
            apiDependencies: ["/api/v1/contacts"],
            availableStates: [.normal, .loading, .empty],
            supportedActions: [],
            sourceFile: "Sources/Contacts/ContactsListViewController.swift",
            sourceLine: 19,
            featureModule: "Contacts",
            discoverySource: .staticSourceAnalysis,
            testMetrics: ScreenTestMetrics(generatedCount: 2, executedCount: 2, passedCount: 2, failedCount: 0, blockedCount: 0, notExecutedCount: 0),
            viewClassName: "ContactsListViewController"
        )

        screens[loginScreen.id] = loginScreen
        screens[homeScreen.id] = homeScreen
        screens[profileScreen.id] = profileScreen
        screens[contactsScreen.id] = contactsScreen

        // Default Journey: Login -> Home -> Profile -> Contacts
        let standardJourney = UserJourney(
            id: "journey_standard_flow",
            name: "Standard User Workflow",
            description: "End-to-end journey from authentication to profile update and contacts inspection",
            initialRoute: "/login",
            steps: [
                JourneyStep(stepNumber: 1, screenId: "screen_login", actionName: "Enter Credentials", targetElementId: "field_email", inputValue: "qa@company.com"),
                JourneyStep(stepNumber: 2, screenId: "screen_login", actionName: "Submit Login", targetElementId: "btn_submit", expectedRoute: "/home", apiCallTriggered: "/api/v1/auth/login"),
                JourneyStep(stepNumber: 3, screenId: "screen_home", actionName: "Open Profile", targetElementId: "btn_profile", expectedRoute: "/profile"),
                JourneyStep(stepNumber: 4, screenId: "screen_profile", actionName: "Save Profile", targetElementId: "btn_save_profile", apiCallTriggered: "/api/v1/profile/update")
            ]
        )

        journeys[standardJourney.id] = standardJourney
    }
}

/// Lightweight developer API facade for 1-line registration.
public enum CompanyTestDiscovery {
    public static func register(_ screen: ScreenDefinition) {
        ScreenRegistry.shared.register(screen)
    }

    public static func registerJourney(_ journey: UserJourney) {
        ScreenRegistry.shared.registerJourney(journey)
    }

    public static var screens: [ScreenDefinition] {
        return ScreenRegistry.shared.allScreens
    }

    public static var journeys: [UserJourney] {
        return ScreenRegistry.shared.allJourneys
    }
}
