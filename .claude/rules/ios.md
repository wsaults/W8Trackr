# iOS Platform Conventions

## Minimum Deployment Target

**iOS 18.0+** - This app uses iOS 18 features:
- SwiftData
- Modern Preview traits (@Previewable, PreviewModifier)
- ContentUnavailableView

Do not use deprecated APIs or iOS 17-and-below patterns.

## Project Structure

```
W8Trackr/
├── W8TrackrApp.swift        # App entry point
├── Models/
│   └── WeightEntry.swift    # SwiftData models
├── Views/
│   ├── ContentView.swift    # Root TabView
│   ├── SummaryView.swift    # Feature views
│   └── ...
└── Managers/
    └── NotificationManager.swift  # Service classes
```

## User Notifications

Use UNUserNotificationCenter:

```swift
class NotificationManager: ObservableObject {
    @Published var isReminderEnabled = false

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isReminderEnabled = granted
                completion(granted)
            }
        }
    }

    func scheduleNotification(at time: Date) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Notification Title"
        content.body = "Notification body text"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "uniqueIdentifier",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }
}
```

### Threading

Always dispatch to main queue for UI updates:

```swift
DispatchQueue.main.async {
    self.isReminderEnabled = granted
}
```

## User Defaults

Use `@AppStorage` for SwiftUI integration:

```swift
@AppStorage("preferredWeightUnit") var preferredWeightUnit: String = "lb"
@AppStorage("goalWeight") var goalWeight: Double = 150.0
```

For managers, use UserDefaults directly:

```swift
private let reminderTimeKey = "reminderTime"

func saveReminderTime(_ time: Date) {
    UserDefaults.standard.set(time, forKey: reminderTimeKey)
}

func getReminderTime() -> Date {
    UserDefaults.standard.object(forKey: reminderTimeKey) as? Date ?? Date()
}
```

## Opening System Settings

```swift
if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
    UIApplication.shared.open(settingsUrl)
}
```

## Simulator vs Device

Use conditional compilation for simulator-specific behavior:

```swift
#if targetEnvironment(simulator)
    // Simulator-only code (sample data, debug tools)
#else
    // Device code
#endif
```

## Keyboard Handling

For numeric input:

```swift
TextField("Goal Weight", value: $localGoalWeight, format: .number.precision(.fractionLength(1)))
    .keyboardType(.decimalPad)
    .multilineTextAlignment(.trailing)
```

## Destructive Actions

Always confirm destructive actions:

```swift
Button(role: .destructive) {
    showingDeleteAlert = true
} label: {
    Text("Delete All Weight Entries")
}
.alert("Delete All Entries", isPresented: $showingDeleteAlert) {
    Button("Cancel", role: .cancel) { }
    Button("Delete", role: .destructive) {
        // Perform deletion
    }
} message: {
    Text("This action cannot be undone.")
}
```

## Date & Calendar

Use Calendar for date manipulation:

```swift
let calendar = Calendar.current
let components = calendar.dateComponents([.hour, .minute], from: time)
let dateWithDays = calendar.date(byAdding: .day, value: daysToAdd, to: startDate)!
```

## SF Symbols

Use SF Symbols for icons:

```swift
Image(systemName: "plus")
Image(systemName: "person.badge.plus")
Image(systemName: "gearshape")
```

Browse symbols at: https://developer.apple.com/sf-symbols/

## App Lifecycle

The app uses the SwiftUI App lifecycle:

```swift
@main
struct W8TrackrApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [WeightEntry.self])
    }
}
```

No AppDelegate or SceneDelegate needed.
