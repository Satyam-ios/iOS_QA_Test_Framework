import Foundation
import CompanyiOSKit

/// Built-in screen and journey catalog for IoT and hardware-connected iOS applications.
public enum IoTAppScreenCatalog {

    /// Registers the standard IoT suite of screens and user journeys into CompanyTestKit.
    public static func registerAllScreens() {
        // 1. Splash Screen
        ScreenRegistry.shared.register(
            id: "screen_splash",
            name: "Splash Screen",
            route: "/splash",
            elements: [
                UIElementDescriptor(id: "img_app_logo", type: .image, accessibilityIdentifier: "splash_logo", accessibilityLabel: "App Logo"),
                UIElementDescriptor(id: "loading_indicator", type: .loadingIndicator, accessibilityIdentifier: "splash_loader", accessibilityLabel: "Loading indicator")
            ],
            apiDependencies: ["/api/v1/auth/check_session"]
        )

        // 2. Login Screen
        ScreenRegistry.shared.register(
            id: "screen_login",
            name: "Login Screen",
            route: "/auth/login",
            elements: [
                UIElementDescriptor(id: "field_email", type: .textField, accessibilityIdentifier: "login_email_field", accessibilityLabel: "Email / Phone"),
                UIElementDescriptor(id: "field_password", type: .secureField, accessibilityIdentifier: "login_password_field", accessibilityLabel: "Password"),
                UIElementDescriptor(id: "btn_login", type: .button, accessibilityIdentifier: "login_submit_btn", accessibilityLabel: "Log In"),
                UIElementDescriptor(id: "btn_forgot_password", type: .button, accessibilityIdentifier: "forgot_password_btn", accessibilityLabel: "Forgot Password")
            ],
            apiDependencies: ["/api/v1/user/login"]
        )

        // 3. User Registration Screen
        ScreenRegistry.shared.register(
            id: "screen_user_registration",
            name: "User Registration",
            route: "/auth/register",
            elements: [
                UIElementDescriptor(id: "field_first_name", type: .textField, accessibilityIdentifier: "reg_first_name", accessibilityLabel: "First Name"),
                UIElementDescriptor(id: "field_reg_email", type: .textField, accessibilityIdentifier: "reg_email", accessibilityLabel: "Email"),
                UIElementDescriptor(id: "btn_continue", type: .button, accessibilityIdentifier: "reg_continue_btn", accessibilityLabel: "Continue")
            ],
            apiDependencies: ["/api/v1/user/register"]
        )

        // 4. Billing Details Screen
        ScreenRegistry.shared.register(
            id: "screen_billing_details",
            name: "Billing Details",
            route: "/billing/details",
            elements: [
                UIElementDescriptor(id: "field_address", type: .textField, accessibilityIdentifier: "billing_address", accessibilityLabel: "Address"),
                UIElementDescriptor(id: "btn_next_card", type: .button, accessibilityIdentifier: "billing_next_btn", accessibilityLabel: "Next")
            ],
            apiDependencies: ["/api/v1/billing/address"]
        )

        // 5. Add Card (Stripe Payment) Screen
        ScreenRegistry.shared.register(
            id: "screen_add_card",
            name: "Add Payment Card",
            route: "/billing/add_card",
            elements: [
                UIElementDescriptor(id: "stripe_card_field", type: .custom, accessibilityIdentifier: "stripe_card_input", accessibilityLabel: "Card Information"),
                UIElementDescriptor(id: "btn_save_card", type: .button, accessibilityIdentifier: "btn_save_card", accessibilityLabel: "Save Card")
            ],
            apiDependencies: ["/api/v1/stripe/attach_payment_method"]
        )

        // 6. Home Dashboard Screen
        ScreenRegistry.shared.register(
            id: "screen_home",
            name: "Home Dashboard",
            route: "/home",
            elements: [
                UIElementDescriptor(id: "lbl_user_greeting", type: .label, accessibilityIdentifier: "user_greeting", accessibilityLabel: "Greeting", textContent: "Welcome, Swati"),
                UIElementDescriptor(id: "list_appliances", type: .list, accessibilityIdentifier: "appliances_collection", accessibilityLabel: "Appliance List"),
                UIElementDescriptor(id: "btn_add_appliance", type: .button, accessibilityIdentifier: "add_appliance_btn", accessibilityLabel: "Add Appliance")
            ],
            apiDependencies: ["/api/v1/appliances/list"]
        )

        // 7. Appliance Grid Screen
        ScreenRegistry.shared.register(
            id: "screen_appliances",
            name: "All Appliances",
            route: "/appliances",
            elements: [
                UIElementDescriptor(id: "grid_appliances", type: .list, accessibilityIdentifier: "appliance_grid", accessibilityLabel: "Appliance Grid"),
                UIElementDescriptor(id: "filter_status", type: .button, accessibilityIdentifier: "filter_status_btn", accessibilityLabel: "Filter Status")
            ],
            apiDependencies: ["/api/v1/appliances/status"]
        )

        // 8. Appliance Details & Control
        ScreenRegistry.shared.register(
            id: "screen_appliance_details",
            name: "Appliance Details & Control",
            route: "/appliances/details",
            elements: [
                UIElementDescriptor(id: "lbl_appliance_name", type: .label, accessibilityIdentifier: "appliance_title", accessibilityLabel: "Device Name"),
                UIElementDescriptor(id: "toggle_power", type: .toggle, accessibilityIdentifier: "power_toggle", accessibilityLabel: "Power Switch")
            ],
            apiDependencies: ["/api/v1/appliances/toggle_power"]
        )

        // 9. Appliance Scanner (Bluetooth & WiFi)
        ScreenRegistry.shared.register(
            id: "screen_appliance_scanner",
            name: "Appliance Scanner",
            route: "/appliances/scan",
            elements: [
                UIElementDescriptor(id: "table_discovered_devices", type: .list, accessibilityIdentifier: "devices_table", accessibilityLabel: "Discovered Peripherals"),
                UIElementDescriptor(id: "btn_start_scan", type: .button, accessibilityIdentifier: "scan_toggle_btn", accessibilityLabel: "Scan Nearby")
            ],
            sourceFile: "HardwareViewController.swift",
            viewClassName: "HardwareViewController"
        )

        // 10. Appliance Scan Details (Hardware Controller)
        ScreenRegistry.shared.register(
            id: "screen_appliance_scan_details",
            name: "Appliance Scan Details",
            route: "/appliances/scan_details",
            elements: [
                UIElementDescriptor(id: "table_device_info", type: .list, accessibilityIdentifier: "device_info_table", accessibilityLabel: "Device Information"),
                UIElementDescriptor(id: "btn_connect_pair", type: .button, accessibilityIdentifier: "connect_pair_btn", accessibilityLabel: "Connect & Pair Device"),
                UIElementDescriptor(id: "btn_unpair", type: .button, accessibilityIdentifier: "unpair_btn", accessibilityLabel: "Unpair Device")
            ],
            sourceFile: "HardwareViewController.swift",
            viewClassName: "AppliaceScanDetailsViewController"
        )

        // 11. Rooms Management
        ScreenRegistry.shared.register(
            id: "screen_rooms",
            name: "Rooms Management",
            route: "/rooms",
            elements: [
                UIElementDescriptor(id: "list_rooms", type: .list, accessibilityIdentifier: "rooms_list", accessibilityLabel: "Rooms List")
            ]
        )

        // 12. Room Appliances List
        ScreenRegistry.shared.register(
            id: "screen_room_appliances",
            name: "Room Appliances List",
            route: "/rooms/appliances",
            elements: [
                UIElementDescriptor(id: "list_room_devices", type: .list, accessibilityIdentifier: "room_devices_list", accessibilityLabel: "Room Devices")
            ]
        )

        // 13. Create / Edit Room
        ScreenRegistry.shared.register(
            id: "screen_edit_room",
            name: "Create / Edit Room",
            route: "/rooms/edit",
            elements: [
                UIElementDescriptor(id: "field_room_name", type: .textField, accessibilityIdentifier: "room_name_field", accessibilityLabel: "Room Name"),
                UIElementDescriptor(id: "btn_save_room", type: .button, accessibilityIdentifier: "save_room_btn", accessibilityLabel: "Save Room")
            ]
        )

        // 14. Scenes List
        ScreenRegistry.shared.register(
            id: "screen_scenes",
            name: "Scenes List",
            route: "/scenes",
            elements: [
                UIElementDescriptor(id: "list_scenes", type: .list, accessibilityIdentifier: "scenes_list", accessibilityLabel: "Automation Scenes")
            ]
        )

        // 15. Create Automation Scene
        ScreenRegistry.shared.register(
            id: "screen_create_scene",
            name: "Create Automation Scene",
            route: "/scenes/create",
            elements: [
                UIElementDescriptor(id: "field_scene_name", type: .textField, accessibilityIdentifier: "scene_name_field", accessibilityLabel: "Scene Name"),
                UIElementDescriptor(id: "btn_save_scene", type: .button, accessibilityIdentifier: "save_scene_btn", accessibilityLabel: "Save Scene")
            ]
        )

        // 16. User Profile
        ScreenRegistry.shared.register(
            id: "screen_profile",
            name: "User Profile",
            route: "/profile",
            elements: [
                UIElementDescriptor(id: "field_user_name", type: .textField, accessibilityIdentifier: "profile_name_field", accessibilityLabel: "Full Name"),
                UIElementDescriptor(id: "btn_save_profile", type: .button, accessibilityIdentifier: "save_profile_btn", accessibilityLabel: "Save Profile")
            ],
            apiDependencies: ["/api/v1/user/profile"]
        )

        // 17. Change Password
        ScreenRegistry.shared.register(
            id: "screen_change_password",
            name: "Change Password",
            route: "/profile/change_password",
            elements: [
                UIElementDescriptor(id: "field_new_password", type: .secureField, accessibilityIdentifier: "new_password_field", accessibilityLabel: "New Password"),
                UIElementDescriptor(id: "btn_update_password", type: .button, accessibilityIdentifier: "update_password_btn", accessibilityLabel: "Update Password")
            ]
        )

        // 18. Application Settings
        ScreenRegistry.shared.register(
            id: "screen_settings",
            name: "Application Settings",
            route: "/settings",
            elements: [
                UIElementDescriptor(id: "btn_open_test_center", type: .button, accessibilityIdentifier: "open_test_center_btn", accessibilityLabel: "Company Test Center"),
                UIElementDescriptor(id: "btn_logout", type: .button, accessibilityIdentifier: "logout_btn", accessibilityLabel: "Log Out")
            ],
            sourceFile: "SettingsViewController.swift",
            viewClassName: "SettingsViewController"
        )

        // 19. Help & Support
        ScreenRegistry.shared.register(
            id: "screen_support",
            name: "Help & Support",
            route: "/support",
            elements: [
                UIElementDescriptor(id: "lbl_support_email", type: .label, accessibilityIdentifier: "support_email", accessibilityLabel: "Contact Support")
            ]
        )

        // Register E2E Journeys
        ScreenRegistry.shared.registerJourney(UserJourney(
            id: "journey_auth_dashboard",
            name: "Authentication to Dashboard",
            description: "User signs in and navigates to the IoT dashboard",
            initialRoute: "/auth/login",
            steps: [
                JourneyStep(stepNumber: 1, screenId: "screen_login", actionName: "Enter Credentials", targetElementId: "field_email", inputValue: "demo@c2c.com"),
                JourneyStep(stepNumber: 2, screenId: "screen_login", actionName: "Submit Login", targetElementId: "btn_login", expectedRoute: "/home")
            ]
        ))

        ScreenRegistry.shared.registerJourney(UserJourney(
            id: "journey_ble_provisioning",
            name: "Bluetooth Appliance Pairing",
            description: "User discovers and pairs Bluetooth appliance",
            initialRoute: "/appliances/scan",
            steps: [
                JourneyStep(stepNumber: 1, screenId: "screen_appliance_scanner", actionName: "Start Scan", targetElementId: "btn_start_scan"),
                JourneyStep(stepNumber: 2, screenId: "screen_appliance_scanner", actionName: "Select Device", targetElementId: "table_discovered_devices", expectedRoute: "/appliances/scan_details"),
                JourneyStep(stepNumber: 3, screenId: "screen_appliance_scan_details", actionName: "Pair Device", targetElementId: "btn_connect_pair")
            ]
        ))
    }
}
